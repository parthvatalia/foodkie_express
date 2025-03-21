import 'package:flutter/material.dart';
import 'package:foodkie_express/screens/home/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/api/profile_service.dart';
import 'package:foodkie_express/models/profile.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/widgets/category_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'menu_screen.dart';
import 'order_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  RestaurantProfile? _restaurantProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantProfile();
  }

  Future<void> _loadRestaurantProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final profile = await profileService.getRestaurantProfile();

      setState(() {
        _restaurantProfile = profile;
        _isLoading = false;
      });

      // If profile doesn't exist, prompt user to create one
      if (profile == null && mounted) {
        _showCreateProfileDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to Foodkie Express'),
        content: const Text(
          'Please set up your restaurant profile to get started.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, AppRoutes.profile);
            },
            child: const Text('Set Up Profile'),
          ),
        ],
      ),
    );
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isLoading
            ? const Text('Foodkie Express')
            : _buildRestaurantTitle(),
        elevation: 0,
        actions: [
          if(_currentIndex != 1)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildHomeTab(),
          const MenuScreen(),
          const OrderHistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changePage,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantTitle() {
    if (_restaurantProfile == null) {
      return const Text('Foodkie Express');
    }

    return Row(
      children: [
        if (_restaurantProfile!.logoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: _restaurantProfile!.logoUrl!,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 30,
                height: 30,
                color: Colors.grey[300],
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _restaurantProfile!.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return _isLoading
        ? Center(
      child: SpinKitDoubleBounce(
        color: Theme.of(context).colorScheme.primary,
        size: 50.0,
      ),
    )
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to your Foodkie Express!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your menu, track orders, and more with our efficient tools.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _changePage(1), // Navigate to Menu tab
                    icon: const Icon(Icons.menu_book),
                    label: const Text('View Menu'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Categories Section
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoriesGrid(),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return StreamBuilder<List<CategoryModel>>(
      stream: Provider.of<MenuService>(context).getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.category,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text('No categories yet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.categoryManagement);
                    },
                    child: const Text('Add Categories'),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:MediaQuery.of(context).size.shortestSide <600?  1.5:2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return CategoryCard(
              category: categories[index],
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.menu,
                  arguments: {'categoryId': categories[index].id},
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: MediaQuery.of(context).size.shortestSide <600?  1.5:2.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _actionCard(
          icon: Icons.add_circle,
          title: 'Add Item',
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, AppRoutes.addItem),
        ),
        _actionCard(
          icon: Icons.category,
          title: 'Manage Categories',
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.categoryManagement),
        ),
        _actionCard(
          icon: Icons.history,
          title: 'View Orders',
          color: Colors.blue,
          onTap: () => _changePage(2),
        ),
        _actionCard(
          icon: Icons.settings,
          title: 'Settings',
          color: Colors.purple,
          onTap: () => _changePage(3),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}