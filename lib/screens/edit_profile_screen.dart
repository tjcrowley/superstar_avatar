import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../providers/avatar_provider.dart';
import '../services/blockchain_service.dart';
import '../widgets/gradient_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _imageUri; // IPFS hash or image URI
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers - will be updated in build
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  void _initializeControllers() {
    final avatar = ref.read(selectedAvatarProvider);
    if (_nameController.text.isEmpty) {
      _nameController.text = avatar?.name ?? '';
    }
    if (_bioController.text.isEmpty) {
      _bioController.text = avatar?.bio ?? '';
    }
    _imageUri ??= avatar?.avatarImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // TODO: Upload image to IPFS or decentralized storage
        // For now, we'll use a placeholder URI
        // In production, integrate with IPFS (e.g., via Pinata, NFT.Storage, etc.)
        _imageUri = 'ipfs://placeholder_hash_${DateTime.now().millisecondsSinceEpoch}';
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected. Upload to IPFS when saving profile.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final avatar = ref.read(selectedAvatarProvider);
      if (avatar == null) {
        throw Exception('No avatar found');
      }

      final blockchainService = BlockchainService();
      
      // Check if avatar exists on blockchain
      final existsOnChain = await blockchainService.avatarExistsOnBlockchain(avatar.id);
      
      if (!existsOnChain) {
        // Create avatar profile on blockchain
        final imageUri = _imageUri ?? 'ipfs://default_avatar';
        await blockchainService.createAvatarProfile(
          avatarId: avatar.id,
          name: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          imageUri: imageUri,
          metadata: '',
        );
      } else {
        // Update existing profile
        final name = _nameController.text.trim();
        final bio = _bioController.text.trim();
        
        // Update profile fields
        if (name.isNotEmpty || bio.isNotEmpty) {
          await blockchainService.updateAvatarProfile(
            avatarId: avatar.id,
            name: name.isNotEmpty ? name : '',
            bio: bio.isNotEmpty ? bio : '',
            metadata: '',
          );
        }
        
        // Update image if changed
        if (_imageUri != null && _imageUri != avatar.avatarImage) {
          await blockchainService.updateAvatarImage(
            avatarId: avatar.id,
            newImageUri: _imageUri!,
          );
        }
      }

      // Update local avatar state
      await ref.read(avatarProvider.notifier).updateAvatar(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
        avatarImage: _imageUri,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(selectedAvatarProvider);
    _initializeControllers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.primaryColor,
                          width: 3,
                        ),
                        boxShadow: AppConstants.shadowMedium,
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : (_imageUri != null && _imageUri!.startsWith('http'))
                                ? Image.network(
                                    _imageUri!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildPlaceholderAvatar(avatar?.name),
                                  )
                                : _buildPlaceholderAvatar(avatar?.name),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your avatar name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < AppConstants.minNameLength) {
                    return 'Name must be at least ${AppConstants.minNameLength} characters';
                  }
                  if (value.trim().length > AppConstants.maxNameLength) {
                    return 'Name must be less than ${AppConstants.maxNameLength} characters';
                  }
                  return null;
                },
                maxLength: AppConstants.maxNameLength,
              ),
              const SizedBox(height: AppConstants.spacingM),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about your avatar',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: AppConstants.maxBioLength,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < AppConstants.minBioLength) {
                      return 'Bio must be at least ${AppConstants.minBioLength} characters';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingXL),

              // Save Button
              GradientButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppConstants.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: AppConstants.spacingM),

              // Info Text
              Text(
                'Your profile will be saved to the Polygon blockchain. This ensures your avatar data is decentralized and persistent.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(String? name) {
    return Container(
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Center(
        child: name != null && name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              )
            : const Icon(
                Icons.person,
                size: 60,
                color: AppConstants.primaryColor,
              ),
      ),
    );
  }
}

