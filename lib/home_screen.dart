import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/card_scanner/presentation/card_scanner_screen.dart';
import 'features/passbook_scanner/presentation/passbook_scanner_screen.dart';

/// Home screen with two large tappable cards for card and passbook scanning.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App header.
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),

              // Scanner cards.
              _ScannerCard(
                icon: Icons.credit_card_rounded,
                title: AppStrings.scanCard,
                subtitle: AppStrings.scanCardSubtitle,
                color: AppTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CardScannerScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ScannerCard(
                icon: Icons.menu_book_rounded,
                title: AppStrings.scanPassbook,
                subtitle: AppStrings.scanPassbookSubtitle,
                color: AppTheme.secondaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PassbookScannerScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large tappable card for navigation to a scanner feature.
class _ScannerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ScannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}
