import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cargo/config/cache_config.dart';
import 'package:cargo/widgets/loading_widgets.dart';

class CacheManagementScreen extends StatefulWidget {
  const CacheManagementScreen({super.key});

  @override
  State<CacheManagementScreen> createState() => _CacheManagementScreenState();
}

class _CacheManagementScreenState extends State<CacheManagementScreen> {
  int _vehicleCacheSize = 0;
  int _profileCacheSize = 0;
  int _chatCacheSize = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSizes();
  }

  Future<void> _loadCacheSizes() async {
    setState(() => _isLoading = true);

    try {
      // ✅ FIX: On web, cache sizes are always 0 (in-memory only)
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _vehicleCacheSize = 0;
            _profileCacheSize = 0;
            _chatCacheSize = 0;
            _isLoading = false;
          });
        }
        return;
      }
      
      final vehicleSize = await VehicleImageCacheManager.getCacheSize();
      
      // Get cache file counts
      int profileSize = 0;
      int chatSize = 0;
      
      try {
        final profileFiles = await ProfileImageCacheManager.instance.store.retrieveCacheData('');
        profileSize = profileFiles?.length ?? 0;
      } catch (_) {
        profileSize = 0;
      }
      
      try {
        final chatFiles = await ChatImageCacheManager.instance.store.retrieveCacheData('');
        chatSize = chatFiles?.length ?? 0;
      } catch (_) {
        chatSize = 0;
      }

      if (mounted) {
        setState(() {
          _vehicleCacheSize = vehicleSize;
          _profileCacheSize = profileSize;
          _chatCacheSize = chatSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cache sizes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearVehicleCache() async {
    final confirmed = await _showConfirmDialog(
      'Clear Vehicle Cache',
      'This will clear all cached car and motorcycle images. They will be downloaded again when needed.',
    );

    if (confirmed != true) return;

    try {
      await VehicleImageCacheManager.clearCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Vehicle cache cleared', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadCacheSizes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearProfileCache() async {
    final confirmed = await _showConfirmDialog(
      'Clear Profile Cache',
      'This will clear all cached profile images.',
    );

    if (confirmed != true) return;

    try {
      await ProfileImageCacheManager.instance.emptyCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Profile cache cleared', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadCacheSizes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await _showConfirmDialog(
      'Clear All Cache',
      'This will clear ALL cached images. The app may load slower until images are cached again.',
    );

    if (confirmed != true) return;

    try {
      await Future.wait([
        VehicleImageCacheManager.clearCache(),
        ProfileImageCacheManager.instance.emptyCache(),
        ChatImageCacheManager.instance.emptyCache(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('All cache cleared', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadCacheSizes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCached = _vehicleCacheSize + _profileCacheSize + _chatCacheSize;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Cache Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: _isLoading
          ? const LoadingScreen(message: 'Loading cache data...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Cache Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.storage, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '$totalCached',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Total Cached Images',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Cache Details',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Vehicle Cache
                  _buildCacheCard(
                    icon: Icons.directions_car,
                    title: 'Vehicle Images',
                    subtitle: 'Cars and motorcycles',
                    count: _vehicleCacheSize,
                    maxCount: 500,
                    color: Colors.orange,
                    onClear: _clearVehicleCache,
                  ),

                  const SizedBox(height: 16),

                  // Profile Cache
                  _buildCacheCard(
                    icon: Icons.person,
                    title: 'Profile Images',
                    subtitle: 'User avatars',
                    count: _profileCacheSize,
                    maxCount: 100,
                    color: Colors.purple,
                    onClear: _clearProfileCache,
                  ),

                  const SizedBox(height: 16),

                  // Chat Cache
                  _buildCacheCard(
                    icon: Icons.chat,
                    title: 'Chat Images',
                    subtitle: 'Message attachments',
                    count: _chatCacheSize,
                    maxCount: 200,
                    color: Colors.green,
                    onClear: () async {
                      final confirmed = await _showConfirmDialog(
                        'Clear Chat Cache',
                        'This will clear all cached chat images.',
                      );
                      if (confirmed == true) {
                        await ChatImageCacheManager.instance.emptyCache();
                        await _loadCacheSizes();
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Clear All Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearAllCache,
                      icon: const Icon(Icons.delete_sweep, size: 22),
                      label: Text(
                        'Clear All Cache',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Images are cached to improve loading speed and reduce data usage. Cache will automatically clear old items.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required int maxCount,
    required Color color,
    required VoidCallback onClear,
  }) {
    final percentage = (count / maxCount * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: Text('Clear', style: GoogleFonts.inter(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count / $maxCount images',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearLoadingBar(
              isLoading: false,
              color: color,
              backgroundColor: Colors.grey.shade200,
              height: 6,
            ),
          ),
        ],
      ),
    );
  }
}
