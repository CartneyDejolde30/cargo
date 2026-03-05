import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/favorite.dart';
import 'services/favorites_service.dart';
import 'services/debug_favorites_service.dart';
import 'car_detail_screen.dart';
import 'motorcycle_detail_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/notification_icon.dart';
import 'package:cargo/widgets/loading_widgets.dart';
import '../../utils/image_helper.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  
  List<Favorite> _allFavorites = [];
  bool _isLoading = true;
  int _selectedNavIndex = 2; // Assuming favorites is at index 2
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        // Tab change triggers rebuild automatically
      });
    }
  }

  Future<void> _loadFavorites({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    // Print debug info to console
    await DebugFavoritesService.printDebugInfo();

    final favorites = await _favoritesService.getFavorites(forceRefresh: forceRefresh);
    
    print('=== FAVORITES LOADED ===');
    print('Total favorites: ${favorites.length}');
    for (var fav in favorites) {
      print('${fav.vehicleType}: ${fav.brand} ${fav.model} (ID: ${fav.vehicleId})');
    }
    print('=== END LOADED ===');
    
    if (mounted) {
      setState(() {
        _allFavorites = favorites;
        _isLoading = false;
      });
    }
  }


  String _formatImage(String? rawPath) {
    return ImageHelper.formatImageUrl(rawPath);
  }

  Future<void> _removeFavorite(Favorite favorite) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove from Favorites',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove ${favorite.fullDisplayName} from your favorites?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removing from favorites...', style: GoogleFonts.poppins()),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Remove favorite
    final result = await _favoritesService.removeFavorite(
      favorite.vehicleType,
      favorite.vehicleId,
    );

    if (mounted) {
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        _loadFavorites(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to remove', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDetail(Favorite favorite) {
    if (favorite.isCar) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CarDetailScreen(
            carId: favorite.vehicleId,
            carName: favorite.fullDisplayName,
            carImage: _formatImage(favorite.image),
            price: favorite.price,
            rating: favorite.rating,
            location: favorite.location,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MotorcycleDetailScreen(
            motorcycleId: favorite.vehicleId,
            motorcycleName: favorite.fullDisplayName,
            motorcycleImage: _formatImage(favorite.image),
            price: favorite.price,
            rating: favorite.rating,
            location: favorite.location,
          ),
        ),
      );
    }
  }

  void _handleNavigation(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/renters');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/my_bookings');
        break;
      case 2:
        // Current screen - do nothing
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chat_list');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final carsCount = _allFavorites.where((f) => f.isCar).length;
    final motorcyclesCount = _allFavorites.where((f) => f.isMotorcycle).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: NotificationIcon(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _loadFavorites(forceRefresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: 'All (${_allFavorites.length})'),
            Tab(text: 'Cars ($carsCount)'),
            Tab(text: 'Motorcycles ($motorcyclesCount)'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingScreen(message: 'Loading favorites...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesList(_allFavorites),
                _buildFavoritesList(_allFavorites.where((f) => f.isCar).toList()),
                _buildFavoritesList(_allFavorites.where((f) => f.isMotorcycle).toList()),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildFavoritesList(List<Favorite> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 20),
              Text(
                'No favorites yet',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding vehicles to your favorites!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/renters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Browse Vehicles',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFavorites(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          return _buildFavoriteCard(favorite);
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Favorite favorite) {
    return GestureDetector(
      onTap: () => _navigateToDetail(favorite),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    _formatImage(favorite.image),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(
                        favorite.isCar ? Icons.directions_car : Icons.two_wheeler,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                // Remove favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(favorite),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Vehicle type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: favorite.isCar ? Colors.blue : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          favorite.isCar ? Icons.directions_car : Icons.two_wheeler,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          favorite.isCar ? 'Car' : 'Motorcycle',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Unlimited mileage badge
                if (favorite.hasUnlimitedMileage)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.all_inclusive, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Unlimited Mileage',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    favorite.fullDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          favorite.location,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Rating and specs
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        favorite.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (favorite.seats != null) ...[
                        Icon(Icons.event_seat, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${favorite.seats} seats',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (favorite.bodyStyle != null) ...[
                        const SizedBox(width: 16),
                        Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            favorite.bodyStyle!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Price
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₱${favorite.price}/day',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
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
}
