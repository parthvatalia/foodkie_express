import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/widgets/animated_button.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryDescriptionController =
      TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();

  CategoryModel? _selectedCategory;
  bool _isAddingCategory = false;
  bool _isEditingCategory = false;
  List<String> _subcategories = [];

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categoryDescriptionController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    setState(() {
      _isAddingCategory = true;
      _isEditingCategory = false;
      _selectedCategory = null;
      _categoryNameController.clear();
      _categoryDescriptionController.clear();
      _subcategories = [];
    });

    _showCategoryDialog();
  }

  void _showEditCategoryDialog(CategoryModel category) {
    setState(() {
      _isAddingCategory = false;
      _isEditingCategory = true;
      _selectedCategory = category;
      _categoryNameController.text = category.name;
      _categoryDescriptionController.text = category.description ?? '';
      _subcategories = List.from(category.subCategories);
    });

    _showCategoryDialog();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    _isAddingCategory ? 'Add Category' : 'Edit Category',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Name
                        TextField(
                          controller: _categoryNameController,
                          decoration: const InputDecoration(
                            labelText: 'Category Name',
                            hintText: 'Enter category name',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextField(
                          controller: _categoryDescriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Enter category description',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 24),

                        // Subcategories
                        const Text(
                          'Subcategories',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Subcategory List
                        if (_subcategories.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children:
                                _subcategories.map((subcat) {
                                  return Chip(
                                    label: Text(subcat),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    onDeleted: () {
                                      setDialogState(() {
                                        _subcategories.remove(subcat);
                                      });
                                    },
                                  );
                                }).toList(),
                          ),

                        const SizedBox(height: 8),

                        // Add Subcategory
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _subcategoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Add Subcategory',
                                  hintText: 'Enter subcategory name',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final subcategory =
                                    _subcategoryController.text.trim();
                                if (subcategory.isNotEmpty) {
                                  setDialogState(() {
                                    _subcategories.add(subcategory);
                                    _subcategoryController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_categoryNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Category name is required'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        if (_isAddingCategory) {
                          _addCategory();
                        } else if (_isEditingCategory &&
                            _selectedCategory != null) {
                          _updateCategory();
                        }
                      },
                      child: Text(_isAddingCategory ? 'Add' : 'Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _addCategory() async {
    try {
      final menuService = Provider.of<MenuService>(context, listen: false);

      // Get the maximum order number to place the new category at the end
      final categories = await menuService.getCategories().first;
      final maxOrder =
          categories.isEmpty
              ? 0
              : categories.map((c) => c.order).reduce((a, b) => a > b ? a : b);

      final newCategory = CategoryModel.create(
        name: _categoryNameController.text.trim(),
        description: _categoryDescriptionController.text.trim(),
        order: maxOrder + 1,
        subCategories: _subcategories,
      );

      await menuService.addCategory(newCategory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding category: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateCategory() async {
    if (_selectedCategory == null) return;

    try {
      final menuService = Provider.of<MenuService>(context, listen: false);

      await menuService.updateCategory(_selectedCategory!.id, {
        'name': _categoryNameController.text.trim(),
        'description': _categoryDescriptionController.text.trim(),
        'subCategories': _subcategories,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating category: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'Are you sure you want to delete "${category.name}"? This will also delete all items in this category.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    final menuService = Provider.of<MenuService>(
                      context,
                      listen: false,
                    );
                    await menuService.deleteCategory(category.id);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting category: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  Future<void> _onCategoriesReordered(int oldIndex, int newIndex) async {
    try {
      final menuService = Provider.of<MenuService>(context, listen: false);
      final categories = await menuService.getCategories().first;

      // Reorder the categories based on the new order
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final items = List<CategoryModel>.from(categories);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      // Update the order property of each category
      for (int i = 0; i < items.length; i++) {
        await menuService.updateCategory(items[i].id, {'order': i});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reordering categories: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: StreamBuilder<List<CategoryModel>>(
        stream: Provider.of<MenuService>(context).getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No categories yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Drag to reorder categories. Tap to edit.'),
                const SizedBox(height: 16),

                Expanded(
                  child: ReorderableListView.builder(
                    onReorder: _onCategoriesReordered,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Card(
                        key: ValueKey(category.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(category.name),
                          subtitle:
                              category.description != null &&
                                      category.description!.isNotEmpty
                                  ? Text(category.description!)
                                  : category.subCategories.isNotEmpty
                                  ? Wrap(
                                    spacing: 4,
                                    children:
                                        category.subCategories.map((subcat) {
                                          return Chip(
                                            label: Text(
                                              subcat,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            padding: EdgeInsets.zero,
                                          );
                                        }).toList(),
                                  )
                                  : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed:
                                    () => _showEditCategoryDialog(category),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteCategory(category),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                          onTap: () => _showEditCategoryDialog(category),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }
}
