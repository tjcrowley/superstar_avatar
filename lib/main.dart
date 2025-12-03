import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'constants/app_constants.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_setup_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'providers/avatar_provider.dart' show setSharedPreferencesInstance, hasAvatarProvider, avatarProvider, AvatarsState;
import 'providers/wallet_provider.dart' show walletProvider, isWalletConnectedProvider;
import 'services/blockchain_service.dart';

// Note: SharedPreferences instance is now cached in avatar_provider.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
  
  // Initialize SharedPreferences and cache the instance
  try {
    final prefsInstance = await SharedPreferences.getInstance();
    // Set the cached instance in the provider file
    setSharedPreferencesInstance(prefsInstance);
    debugPrint('✓ SharedPreferences initialized');
  } catch (e, stack) {
    debugPrint('✗ Failed to initialize SharedPreferences: $e');
    debugPrint('Stack: $stack');
  }
  
  try {
    await Hive.initFlutter();
    debugPrint('✓ Hive initialized');
  } catch (e, stack) {
    debugPrint('✗ Failed to initialize Hive: $e');
    debugPrint('Stack: $stack');
  }
  
  try {
    await BlockchainService().initialize();
    debugPrint('✓ BlockchainService initialized');
  } catch (e, stack) {
    debugPrint('✗ Failed to initialize BlockchainService: $e');
    debugPrint('Stack: $stack');
    // Continue anyway - service will retry when needed
  }
  
  // Initialize Stripe (optional - only if key is provided)
  try {
    if (AppConstants.stripePublishableKey.isNotEmpty && 
        AppConstants.stripePublishableKey != 'YOUR_STRIPE_PUBLISHABLE_KEY') {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      Stripe.merchantIdentifier = 'merchant.com.superstaravatar';
      await Stripe.instance.applySettings();
      debugPrint('✓ Stripe initialized');
    } else {
      debugPrint('⚠ Stripe not configured (using placeholder key)');
    }
  } catch (e, stack) {
    debugPrint('✗ Failed to initialize Stripe: $e');
    debugPrint('Stack: $stack');
    // Continue anyway - Stripe features will be disabled
  }
  
  debugPrint('🚀 Starting app...');
  runApp(const ProviderScope(child: SuperstarAvatarApp()));
}

class SuperstarAvatarApp extends ConsumerWidget {
  const SuperstarAvatarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
        home: const AppRouter(),
          routes: {
            '/edit-profile': (context) => const EditProfileScreen(),
            '/admin': (context) => AdminDashboardScreen(),
          },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeXXXLarge,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimaryColor,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimaryColor,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeMedium,
          color: AppConstants.textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeMedium,
          color: AppConstants.textSecondaryColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeMedium,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: AppConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: const BorderSide(color: AppConstants.textSecondaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: const BorderSide(color: AppConstants.textSecondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        ),
        color: AppConstants.surfaceColor,
        shadowColor: AppConstants.textPrimaryColor.withValues(alpha: 0.1),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: AppConstants.textPrimaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppConstants.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimaryColor,
        ),
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
    );
  }
}

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Mark as initialized after first frame to allow ref.watch to work
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      // Show loading screen until after first frame to prevent reading providers during initial build
      if (!_isInitialized) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      // Now safe to use ref.watch - providers are already initialized
      // Use select to only watch the specific values we need to minimize rebuilds
      final isWalletConnected = ref.watch(walletProvider);
      final hasAvatar = ref.watch(
        avatarProvider.select((state) => state.hasAvatar),
      );

      // Check if wallet is connected
      if (!isWalletConnected) {
        return const WalletSetupScreen();
      }

      // Check if avatar exists
      if (!hasAvatar) {
        return const OnboardingScreen();
      }

      // Check if user is admin and show admin dashboard if accessing admin route
      // Main app
      return const HomeScreen();
    } catch (e, stack) {
      debugPrint('Error in AppRouter: $e');
      debugPrint('Stack: $stack');
      return ErrorScreen(error: e, stackTrace: stack);
    }
  }
}

class ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;
  
  const ErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              ElevatedButton(
                onPressed: () {
                  // Restart app by navigating to wallet setup
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WalletSetupScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Restart App'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppConstants.spacingM),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: 'Error: $error\n\nStack: $stackTrace',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error copied to clipboard')),
                    );
                  },
                  child: const Text('Copy Error Details'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                Icons.star,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              AppConstants.appDescription,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXL),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
