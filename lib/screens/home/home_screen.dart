import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodkie_express/screens/home/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/api/profile_service.dart';
import 'package:foodkie_express/models/profile.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/widgets/category_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../../utils/menu_data_loader.dart';
import '../../utils/update_checker.dart';
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

    UpdateChecker(context).checkForUpdates();
  }

  static Future<void> setupOrderCounter(String userId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      final counterDoc =
          await firestore
              .collection('users')
              .doc(userId)
              .collection('counters')
              .doc('orders')
              .get();

      if (!counterDoc.exists) {
        await firestore
            .collection('users')
            .doc(userId)
            .collection('counters')
            .doc('orders')
            .set({
              'currentCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        debugPrint('Order counter initialized for user $userId');
      } else {
        debugPrint('Order counter already exists for user $userId');
      }
    } catch (e) {
      debugPrint('Error setting up order counter: $e');
    }
  }

  loadMenu() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await MenuDataLoader.loadInitialMenuData(user.uid);
    }
  }

  Future<void> _loadRestaurantProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );
      final profile = await profileService.getRestaurantProfile();

      setState(() {
        _restaurantProfile = profile;
        _isLoading = false;
      });
      final user = fa.FirebaseAuth.instance.currentUser;
      await setupOrderCounter(user!.uid);

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
      builder:
          (context) => AlertDialog(
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
        title:
            _isLoading
                ? const Text('Foodkie Express')
                : _buildRestaurantTitle(),
        elevation: 0,
        actions: [
          if (_currentIndex != 1)
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
              placeholder:
                  (context, url) =>
                      Container(width: 30, height: 30, color: Colors.grey[300]),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome to your Foodkie Express!',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your menu, track orders, and more with our efficient tools.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _changePage(1),
                          icon: const Icon(Icons.menu_book),
                          label: const Text('View Menu'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildQuickActions(),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildCategoriesList(),

              const SizedBox(height: 10),
            ],
          ),
        );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<CategoryModel>>(
      stream: Provider.of<MenuService>(context).getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading categories: ${snapshot.error}'),
                const SizedBox(height: 16),
              ],
            ),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text(
                    'No categories yet',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.categoryManagement,
                      );
                    },
                    child: const Text('Add Categories'),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
      padding: const EdgeInsets.all(8),
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _actionCard(
          icon: Icons.add_circle,
          title: 'Add Food',
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, AppRoutes.addItem),
        ),
        _actionCard(
          icon: Icons.category,
          title: 'Manage Categories',
          color: Colors.orange,
          onTap:
              () => Navigator.pushNamed(context, AppRoutes.categoryManagement),
        ),
        _actionCard(
          icon: Icons.history,
          title: 'View Orders',
          color: Colors.blue,
          onTap: () => _changePage(2),
        ),
        _actionCard(
          icon: Icons.bar_chart,
          title: 'Sales Analytics',
          color: Colors.deepPurple,
          onTap: () => Navigator.pushNamed(context, AppRoutes.salesAnalytics),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
