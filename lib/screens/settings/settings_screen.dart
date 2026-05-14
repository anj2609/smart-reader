import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/reader_settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final readerSettings = context.watch<ReaderSettingsProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // App Theme
            _SectionTitle(title: 'Appearance'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.palette_rounded,
              iconColor: AppColors.primary,
              title: 'App Theme',
              subtitle: isDark ? 'Dark Mode' : 'Light Mode',
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.text_fields_rounded,
              iconColor: AppColors.accent,
              title: 'Default Font Size',
              subtitle: '${readerSettings.fontSize.round()} pt',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniButton(icon: Icons.remove_rounded, onTap: readerSettings.decreaseFontSize),
                  const SizedBox(width: 8),
                  _MiniButton(icon: Icons.add_rounded, onTap: readerSettings.increaseFontSize),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.format_line_spacing_rounded,
              iconColor: AppColors.secondary,
              title: 'Line Spacing',
              subtitle: '${readerSettings.lineSpacing.toStringAsFixed(1)}x',
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: readerSettings.lineSpacing,
                  min: 1.0, max: 3.0, divisions: 8,
                  onChanged: (v) => readerSettings.setLineSpacing(v),
                  activeColor: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Reader Theme
            _SectionTitle(title: 'Reader Theme'),
            const SizedBox(height: 12),
            Row(
              children: List.generate(ReaderSettingsProvider.readerThemes.length, (i) {
                final t = ReaderSettingsProvider.readerThemes[i];
                final sel = readerSettings.readerThemeIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => readerSettings.setReaderTheme(i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: t['bg'],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: sel ? AppColors.primary : Colors.grey.withAlpha(50), width: sel ? 2.5 : 1),
                      ),
                      child: Column(children: [
                        Text('Aa', style: TextStyle(color: t['text'], fontWeight: FontWeight.w600, fontSize: 18)),
                        const SizedBox(height: 6),
                        Text(ReaderSettingsProvider.readerThemeNames[i], style: TextStyle(color: t['text']?.withAlpha(150), fontSize: 10)),
                      ]),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // About
            _SectionTitle(title: 'About'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.info,
              title: AppConstants.appName,
              subtitle: 'Version ${AppConstants.appVersion}',
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.description_outlined,
              iconColor: AppColors.accent,
              title: 'About',
              subtitle: AppConstants.appDescription,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        border: Border.all(color: AppColors.primary.withAlpha(isDark ? 40 : 25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withAlpha(isDark ? 30 : 20), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: trailing,
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}
