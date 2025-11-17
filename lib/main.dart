import 'package:flutter/material.dart';
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
import 'providers/avatar_provider.dart';
import 'providers/wallet_provider.dart';
import 'services/blockchain_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await SharedPreferences.getInstance();
  await Hive.initFlutter();
  await BlockchainService().initialize();
  
  // Initialize Stripe
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.superstaravatar';
  await Stripe.instance.applySettings();
  
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

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAvatar = ref.watch(hasAvatarProvider);
    final isWalletConnected = ref.watch(isWalletConnectedProvider);

    // Check if wallet is connected
    if (!isWalletConnected) {
      return const WalletSetupScreen();
    }

    // Check if avatar exists
    if (!hasAvatar) {
      return const OnboardingScreen();
    }

    // Main app
    return const HomeScreen();
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
