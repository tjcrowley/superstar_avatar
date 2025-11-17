import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/avatar_provider.dart';
import '../widgets/gradient_button.dart';
import '../models/power.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  int _currentStep = 0;
  bool _isCreatingAvatar = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _createAvatar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingAvatar = true;
    });

    try {
      await ref.read(avatarProvider.notifier).createPrimaryAvatar(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty ? _bioController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create avatar: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingAvatar = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPowersStep();
      case 2:
        return _buildProfileStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppConstants.primaryGradient,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXL),
            boxShadow: AppConstants.shadowLarge,
          ),
          child: const Icon(
            Icons.person_add,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Text(
          AppConstants.onboardingTitles[0],
          style: Theme.of(context).textTheme.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.onboardingDescriptions[0],
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXL),
        GradientButton(
          onPressed: _nextStep,
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _buildPowersStep() {
    return Column(
      children: [
        Text(
          AppConstants.onboardingTitles[1],
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.onboardingDescriptions[1],
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingL),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.spacingM,
              mainAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 1.2,
            ),
            itemCount: Power.defaultPowers.length,
            itemBuilder: (context, index) {
              final power = Power.defaultPowers[index];
              final color = AppConstants.powerColors[power.type.toString().split('.').last];
              
              return Card(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color!.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          power.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Text(
                          power.name,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spacingXS),
                        Text(
                          power.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        Row(
          children: [
            OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
            const Spacer(),
            GradientButton(
              onPressed: _nextStep,
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            AppConstants.onboardingTitles[2],
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            AppConstants.onboardingDescriptions[2],
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Avatar Image Selection (placeholder)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusXXL),
              border: Border.all(color: AppConstants.primaryColor),
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          TextButton(
            onPressed: () {
              // TODO: Implement avatar image selection
            },
            child: const Text('Choose Avatar Image'),
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Name Input
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Avatar Name',
              hintText: 'Enter your avatar name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your avatar name';
              }
              if (value.trim().length < AppConstants.minNameLength) {
                return 'Name must be at least ${AppConstants.minNameLength} characters';
              }
              if (value.trim().length > AppConstants.maxNameLength) {
                return 'Name must be less than ${AppConstants.maxNameLength} characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          
          // Bio Input
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio (Optional)',
              hintText: 'Tell us about yourself',
            ),
            maxLines: 3,
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
          const SizedBox(height: AppConstants.spacingL),
          
          Row(
            children: [
              OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
              const Spacer(),
              GradientButton(
                onPressed: _isCreatingAvatar ? null : _createAvatar,
                child: _isCreatingAvatar
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Avatar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: AppConstants.textSecondaryColor.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Step Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentStep 
                          ? AppConstants.primaryColor 
                          : AppConstants.textSecondaryColor.withOpacity(0.3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppConstants.spacingL),
              
              // Content
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 