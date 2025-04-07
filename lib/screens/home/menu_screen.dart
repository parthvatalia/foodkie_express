import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/screens/home/controllers/cart_provider.dart';
import 'package:foodkie_express/widgets/menu_item_card.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MenuScreen extends StatefulWidget {
  final String? categoryId;

  const MenuScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _selectedCategoryId;
  String? _selectedSubCategory;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<MenuItemModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    
    
    if (widget.categoryId != null) {
      _selectedCategoryId = widget.categoryId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await Provider.of<MenuService>(
        context,
        listen: false,
      ).searchItems(query);

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 8,
                        top: 18,
                        bottom: 8,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search menu items...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _performSearch('');
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          _performSearch(value);
                        },
                      ),
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder:
                        (context, cartProvider, _) => IconButton(
                          icon: Stack(
                            children: [
                              const Icon(Icons.shopping_cart, size: 30),
                              if (cartProvider.itemCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${cartProvider.itemCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, AppRoutes.cart),
                        ),
                  ),
                ],
              ),
            ),

            
            if (!_isSearching) _buildCategoryTabs(),

            
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildMenuItems(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Add Food"),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.addItem,
            arguments: {'categoryId': _selectedCategoryId},
          );
        },
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return StreamBuilder<List<CategoryModel>>(
      stream: Provider.of<MenuService>(context).getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 50,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return SizedBox(
            height: 50,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.categoryManagement);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Categories'),
              ),
            ),
          );
        }

        return Column(
          children: [
            
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1, 
                itemBuilder: (context, index) {
                  
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryId = null;
                              _selectedSubCategory = null;
                            });
                          }
                        },
                      ),
                    );
                  }

                  
                  final category = categories[index - 1];
                  final isSelected = category.id == _selectedCategoryId;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryId = category.id;
                            _selectedSubCategory = null;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            
            if (_selectedCategoryId != null) _buildSubCategoryTabs(categories),
          ],
        );
      },
    );
  }

  Widget _buildSubCategoryTabs(List<CategoryModel> categories) {
    
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => const CategoryModel(id: '', name: '', order: 0),
    );

    if (selectedCategory.subCategories.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedCategory.subCategories.length + 1,
        
        itemBuilder: (context, index) {
          
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: _selectedSubCategory == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSubCategory = null;
                    });
                  }
                },
              ),
            );
          }

          final subCategory = selectedCategory.subCategories[index - 1];
          final isSelected = subCategory == _selectedSubCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(subCategory),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedSubCategory = subCategory;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItems() {
    
    if (_selectedCategoryId == null) {
      return StreamBuilder<List<MenuItemModel>>(
        stream: Provider.of<MenuService>(context).getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No items available'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.addItem);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 70,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: MenuItemCard(
                        item: items[index],
                        onTap: () => _showItemOptions(items[index]),
                        onAddToCart: () => _addToCart(items[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    
    return StreamBuilder<List<MenuItemModel>>(
      stream: Provider.of<MenuService>(
        context,
      ).getMenuItems(categoryId: _selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data ?? [];

        
        final filteredItems =
            _selectedSubCategory != null
                ? items
                    .where((item) => item.subCategory == _selectedSubCategory)
                    .toList()
                : items;

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No items in this category'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addItem,
                      arguments: {'categoryId': _selectedCategoryId},
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 70,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: MenuItemCard(
                      item: filteredItems[index],
                      onTap: () => _showItemOptions(filteredItems[index]),
                      onAddToCart: () => _addToCart(filteredItems[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return MenuItemCard(
          item: _searchResults[index],
          onTap: () => _showItemOptions(_searchResults[index]),
          onAddToCart: () => _addToCart(_searchResults[index]),
        );
      },
    );
  }

  void _showItemOptions(MenuItemModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Item'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editItem,
                    arguments: {'item': item},
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  item.isAvailable ? Icons.visibility_off : Icons.visibility,
                ),
                title: Text(
                  item.isAvailable
                      ? 'Mark as Unavailable'
                      : 'Mark as Available',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleItemAvailability(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Add to Cart'),
                onTap: () {
                  Navigator.pop(context);
                  _addToCart(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleItemAvailability(MenuItemModel item) async {
    try {
      await Provider.of<MenuService>(
        context,
        listen: false,
      ).updateMenuItem(item.id, {'isAvailable': !item.isAvailable}, null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item.isAvailable
                ? '${item.name} marked as unavailable'
                : '${item.name} marked as available',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addToCart(MenuItemModel item) {
    if (!item.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} is currently unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    
    cartProvider.addItem(id: item.id, name: item.name, price: item.price);

    
    final totalCategoryItems =
        cartProvider.items
            .firstWhere((cartItem) => cartItem.name == item.name)
            .quantity
            .toString();

    
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    AnimatedSnackBar.material(
      'total $totalCategoryItems ${item.name} added to the cart',
      type: AnimatedSnackBarType.success,
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
      duration: const Duration(seconds: 2),
    ).show(context);
  }
}
