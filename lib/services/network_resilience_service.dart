import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Service to handle network resilience with circuit breaker pattern.
///
/// Notes:
/// - TLS errors in Flutter are typically thrown as [HandshakeException] (dart:io)
///   and were previously falling into the generic catch, preventing retries.
/// - A single [http.Client] is reused to reduce repeated TCP/TLS handshakes.
class NetworkResilienceService {
  static final NetworkResilienceService _instance =
      NetworkResilienceService._internal();
  factory NetworkResilienceService() => _instance;
  NetworkResilienceService._internal();

  // Reuse one client to reduce TLS handshakes.
  // (We intentionally never close it because this service is a singleton.)
  final http.Client _client = http.Client();

  // Circuit breaker state
  final Map<String, CircuitBreakerState> _circuitBreakers = {};

  /// Check if network is available.
  static Future<bool> isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  /// Get circuit breaker for an endpoint.
  CircuitBreakerState getCircuitBreaker(String endpoint) {
    return _circuitBreakers.putIfAbsent(
      endpoint,
      () => CircuitBreakerState(endpoint),
    );
  }

  /// Reset circuit breaker for an endpoint.
  void resetCircuitBreaker(String endpoint) {
    _circuitBreakers[endpoint]?.reset();
  }

  /// Reset all circuit breakers.
  void resetAllCircuitBreakers() {
    _circuitBreakers.clear();
  }

  static bool _isRetryableError(Object e) {
    return e is TimeoutException ||
        e is HandshakeException ||
        e is SocketException ||
        e is http.ClientException;
  }

  static String _errorLabel(Object e) {
    if (e is TimeoutException) return 'Timeout';
    if (e is HandshakeException) return 'TLS handshake';
    if (e is SocketException) return 'Socket';
    if (e is http.ClientException) return 'HTTP client';
    return 'Unexpected';
  }

  Duration _computeBackoffDelay(int attempt) {
    // Exponential backoff with jitter, capped.
    // attempt is 1-based.
    final baseMs = 500 * pow(2, (attempt - 1)).toInt();
    final cappedMs = min(baseMs, 8000);
    final jitterMs = Random().nextInt(300);
    return Duration(milliseconds: cappedMs + jitterMs);
  }

  /// Make a resilient GET request with circuit breaker.
  ///
  /// Returns null if:
  /// - circuit breaker is open
  /// - there is no network
  /// - all retries failed
  Future<http.Response?> resilientGet(
    Uri url, {
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    final circuitBreaker = getCircuitBreaker(url.toString());

    if (circuitBreaker.isOpen) {
      print('🚫 Circuit breaker OPEN for $url. Skipping request.');
      return null;
    }

    if (!await isNetworkAvailable()) {
      print('📵 No network connection available');
      circuitBreaker.recordFailure();
      return null;
    }

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client.get(url).timeout(timeout);

        // Consider transport success as success. (HTTP-level errors can be
        // handled by callers.)
        circuitBreaker.recordSuccess();
        return response;
      } catch (e) {
        final retryable = _isRetryableError(e);

        // Record failure for circuit breaker purposes.
        circuitBreaker.recordFailure();

        final label = _errorLabel(e);
        print('🔌 $label error (attempt $attempt/$maxRetries) for $url: $e');

        if (!retryable || attempt >= maxRetries) {
          return null;
        }

        await Future.delayed(_computeBackoffDelay(attempt));
      }
    }

    return null;
  }
}

/// Circuit breaker state for an endpoint.
class CircuitBreakerState {
  final String endpoint;
  int failureCount = 0;
  DateTime? lastFailureTime;
  bool _isOpen = false;

  // Circuit breaker thresholds
  static const int failureThreshold = 5;
  static const Duration openDuration = Duration(minutes: 5);

  CircuitBreakerState(this.endpoint);

  bool get isOpen {
    if (!_isOpen) return false;

    if (lastFailureTime != null) {
      final timeSinceFailure = DateTime.now().difference(lastFailureTime!);

      if (timeSinceFailure > openDuration) {
        print('🔄 Circuit breaker moving to HALF-OPEN for $endpoint');
        _isOpen = false;
        failureCount = 0;
        return false;
      }
    }

    return true;
  }

  void recordSuccess() {
    failureCount = 0;
    _isOpen = false;
    lastFailureTime = null;
    // Keep this log minimal; it can be noisy on frequent polling.
    // print('✅ Circuit breaker SUCCESS for $endpoint');
  }

  void recordFailure() {
    failureCount++;
    lastFailureTime = DateTime.now();

    if (failureCount >= failureThreshold && !_isOpen) {
      _isOpen = true;
      print('⚠️ Circuit breaker OPENED for $endpoint after $failureCount failures');
    } else if (!_isOpen) {
      print(
          '⚠️ Circuit breaker failure count: $failureCount/$failureThreshold for $endpoint');
    }
  }

  void reset() {
    failureCount = 0;
    _isOpen = false;
    lastFailureTime = null;
    print('🔄 Circuit breaker RESET for $endpoint');
  }
}
