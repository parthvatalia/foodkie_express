import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/widgets/animated_button.dart';

class EditItemScreen extends StatefulWidget {
  final MenuItemModel item;

  const EditItemScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  late String _selectedCategoryId;
  String? _selectedSubCategory;
  File? _imageFile;
  late bool _isAvailable;
  late bool _isFeatured;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
      text: widget.item.price.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );

    _selectedCategoryId = widget.item.categoryId;
    _selectedSubCategory = widget.item.subCategory;
    _isAvailable = widget.item.isAvailable;
    _isFeatured = widget.item.isFeatured;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final double price = double.parse(_priceController.text.trim());

      
      final updateData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'categoryId': _selectedCategoryId,
        'subCategory': _selectedSubCategory,
        'isAvailable': _isAvailable,
        'isFeatured': _isFeatured,
      };

      final menuService = Provider.of<MenuService>(context, listen: false);
      await menuService.updateMenuItem(widget.item.id, updateData, _imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text(
              'Are you sure you want to delete "${widget.item.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  _confirmDelete().then((val) => {Navigator.pop(context)});
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<dynamic> _confirmEditItem() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Item'),
            content: Text(
              'Are you sure you want to Edit "${widget.item.name}"?',
            ),
            actions: [

              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('go to Menu'),

              ),
              TextButton(
                onPressed: () async {
                  _updateItem();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Yes Edit it'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final menuService = Provider.of<MenuService>(context, listen: false);
      await menuService.deleteMenuItem(widget.item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _confirmEditItem().then((val) {
          Navigator.pop(context);
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Menu Item'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteItem,
              tooltip: 'Delete Item',
            ),
          ],
        ),
        body:
            _isDeleting
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                image:
                                    _imageFile != null
                                        ? DecorationImage(
                                          image: FileImage(_imageFile!),
                                          fit: BoxFit.cover,
                                        )
                                        : widget.item.imageUrl != null
                                        ? DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            widget.item.imageUrl!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                              ),
                              child:
                                  _imageFile == null &&
                                          widget.item.imageUrl == null
                                      ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      )
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Item Details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            hintText: 'Enter item name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Item name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price (₹)',
                            hintText: 'Enter price',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Price is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Enter item description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Category',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        
                        StreamBuilder<List<CategoryModel>>(
                          stream:
                              Provider.of<MenuService>(context).getCategories(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final categories = snapshot.data ?? [];

                            if (categories.isEmpty) {
                              return Column(
                                children: [
                                  const Text('No categories available'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/category-management',
                                      );
                                    },
                                    child: const Text('Add Categories'),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                DropdownButtonFormField<String>(
                                  value: _selectedCategoryId,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items:
                                      categories.map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category.id,
                                          child: Text(category.name),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCategoryId = value;
                                        _selectedSubCategory =
                                            null; 
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                
                                categories
                                        .firstWhere(
                                          (c) => c.id == _selectedCategoryId,
                                          orElse:
                                              () => const CategoryModel(
                                                id: '',
                                                name: '',
                                                order: 0,
                                              ),
                                        )
                                        .subCategories
                                        .isNotEmpty
                                    ? DropdownButtonFormField<String>(
                                      value: _selectedSubCategory,
                                      decoration: InputDecoration(
                                        labelText: 'Subcategory (Optional)',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      items: [
                                        const DropdownMenuItem<String>(
                                          value: null,
                                          child: Text('-- None --'),
                                        ),
                                        ...categories
                                            .firstWhere(
                                              (c) =>
                                                  c.id == _selectedCategoryId,
                                              orElse:
                                                  () => const CategoryModel(
                                                    id: '',
                                                    name: '',
                                                    order: 0,
                                                  ),
                                            )
                                            .subCategories
                                            .map((subCategory) {
                                              return DropdownMenuItem<String>(
                                                value: subCategory,
                                                child: Text(subCategory),
                                              );
                                            })
                                            .toList(),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSubCategory = value;
                                        });
                                      },
                                    )
                                    : const SizedBox(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        
                        SwitchListTile(
                          title: const Text('Available'),
                          subtitle: const Text(
                            'Toggle if this item is currently available',
                          ),
                          value: _isAvailable,
                          onChanged: (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),

                        
                        SwitchListTile(
                          title: const Text('Featured'),
                          subtitle: const Text(
                            'Toggle if this is a featured item',
                          ),
                          value: _isFeatured,
                          onChanged: (value) {
                            setState(() {
                              _isFeatured = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 32),

                        
                        AnimatedButton(
                          onPressed: _isLoading ? null : _updateItem,
                          isLoading: _isLoading,
                          child: const Text('Update Item'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
