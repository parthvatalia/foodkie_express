import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodkie_express/api/menu_service.dart';
import 'package:foodkie_express/models/category.dart';
import 'package:foodkie_express/models/item.dart';
import 'package:foodkie_express/widgets/animated_button.dart';

class AddItemScreen extends StatefulWidget {
  final String? categoryId;

  const AddItemScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubCategory;
  File? _imageFile;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double price = double.parse(_priceController.text.trim());

      final newItem = MenuItemModel.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        categoryId: _selectedCategoryId!,
        subCategory: _selectedSubCategory,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
      );

      final menuService = Provider.of<MenuService>(context, listen: false);
      await menuService.addMenuItem(newItem, _imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding item: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Menu Item'),
      ),
      body: SingleChildScrollView(
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
                      image: _imageFile != null
                          ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              
              StreamBuilder<List<CategoryModel>>(
                stream: Provider.of<MenuService>(context).getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
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
                            Navigator.pushNamed(context, '/category-management');
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
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                            _selectedSubCategory = null; 
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      
                      if (_selectedCategoryId != null) ...[
                        
                        categories.firstWhere(
                              (c) => c.id == _selectedCategoryId,
                          orElse: () => const CategoryModel(id: '', name: '', order: 0),
                        ).subCategories.isNotEmpty
                            ? DropdownButtonFormField<String>(
                          value: _selectedSubCategory,
                          decoration: InputDecoration(
                            labelText: 'Subcategory (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('-- None --'),
                            ),
                            ...categories
                                .firstWhere(
                                  (c) => c.id == _selectedCategoryId,
                              orElse: () => const CategoryModel(id: '', name: '', order: 0),
                            )
                                .subCategories
                                .map((subCategory) {
                              return DropdownMenuItem<String>(
                                value: subCategory,
                                child: Text(subCategory),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSubCategory = value;
                            });
                          },
                        )
                            : const SizedBox(),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Toggle if this item is currently available'),
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
                subtitle: const Text('Toggle if this is a featured item'),
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
                onPressed: _isLoading ? null : _saveItem,
                isLoading: _isLoading,
                child: const Text('Add Item'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}