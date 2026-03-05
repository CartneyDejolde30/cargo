/// ImgBB API Configuration
/// Free unlimited image hosting with CDN
class ImgBBConfig {
  // ImgBB API Key - Free tier with unlimited storage
  static const String apiKey = '52d27fca0659d9b90733a6680f4261e7';
  
  // API Endpoint
  static const String uploadEndpoint = 'https://api.imgbb.com/1/upload';
  
  // CDN Base URL
  static const String cdnBase = 'https://i.ibb.co';
  
  // Max file size (32MB for free tier)
  static const int maxFileSizeBytes = 32 * 1024 * 1024;
  
  // Timeout duration
  static const Duration uploadTimeout = Duration(seconds: 30);
}
