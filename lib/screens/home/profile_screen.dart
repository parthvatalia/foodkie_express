import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foodkie_express/screens/settings/bluetooth_printer_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:foodkie_express/api/profile_service.dart';
import 'package:foodkie_express/models/profile.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart';
import 'package:foodkie_express/widgets/animated_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _logoFile;
  bool _isLoading = false;
  RestaurantProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
        _profile = profile;

        
        if (profile != null) {
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber ?? '';
          _emailController.text = profile.email ?? '';
          _addressController.text = profile.address ?? '';
          _cityController.text = profile.city ?? '';
          _stateController.text = profile.state ?? '';
          _zipCodeController.text = profile.zipCode ?? '';
          _descriptionController.text = profile.description ?? '';
        }

        _isLoading = false;
      });
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

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = Provider.of<ProfileService>(
        context,
        listen: false,
      );

      final updatedProfile = RestaurantProfile(
        name: _nameController.text.trim(),
        logoUrl: _profile?.logoUrl,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      await profileService.saveRestaurantProfile(
        updatedProfile,
        logoFile: _logoFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
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

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).signOut();
                    AppRoutes.navigateToLogin();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Center(
                          child: Stack(
                            children: [
                              
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      _logoFile != null
                                          ? FileImage(_logoFile!)
                                          : _profile?.logoUrl != null
                                          ? CachedNetworkImageProvider(
                                            _profile!.logoUrl!,
                                          )
                                          : null,
                                  child:
                                      _logoFile == null &&
                                              _profile?.logoUrl == null
                                          ? Icon(
                                            Icons.restaurant,
                                            size: 60,
                                            color: Colors.grey[400],
                                          )
                                          : null,
                                ),
                              ),
                              
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(0),
                                  margin: EdgeInsets.zero,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 25,
                                    ),
                                    color: Colors.white,
                                    onPressed: _pickImage,
                                    tooltip: 'Change Logo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Basic Information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Restaurant Name',
                            hintText: 'Enter your restaurant name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Restaurant name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter contact phone number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email (Optional)',
                            hintText: 'Enter contact email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Address Information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Street Address',
                            hintText: 'Enter street address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        
                        Row(
                          children: [
                            
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText: 'City',
                                  hintText: 'Enter city',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                  hintText: 'Enter state',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        
                        TextFormField(
                          controller: _zipCodeController,
                          decoration: InputDecoration(
                            labelText: 'Zip/Postal Code',
                            hintText: 'Enter zip code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Additional Information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Restaurant Description',
                            hintText:
                                'Enter a short description of your restaurant',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),

                        
                        AnimatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          isLoading: _isLoading,
                          child: const Text('Save Profile'),
                        ),
                        const SizedBox(height: 24),

                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        

                        
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.print),
                                title: const Text('Printer setup'),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const BluetoothPrinterSelectionScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Sign Out'),
                                textColor: Colors.red,
                                iconColor: Colors.red,
                                onTap: _signOut,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Foodkie Express',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version 1.0.0',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
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
