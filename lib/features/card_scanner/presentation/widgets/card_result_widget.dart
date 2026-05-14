import 'package:flutter/material.dart';
import 'package:smart_reader/core/theme/app_theme.dart';
import 'package:smart_reader/core/constants/app_strings.dart';
import 'package:smart_reader/features/card_scanner/domain/models/card_details.dart';

/// Displays the parsed card details in a styled result card.
class CardResultWidget extends StatelessWidget {
  /// The parsed card details to display.
  final CardDetails details;

  /// Creates a [CardResultWidget].
  const CardResultWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          _buildField(context, AppStrings.cardNumber,
              details.maskedNumber.isNotEmpty ? details.maskedNumber : AppStrings.notDetected),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField(context, AppStrings.expiryDate,
                  details.expiryDate ?? AppStrings.notDetected)),
              const SizedBox(width: 16),
              Expanded(child: _buildField(context, AppStrings.cardNetwork,
                  details.cardNetwork ?? AppStrings.notDetected)),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(context, AppStrings.cardHolder,
              details.cardHolderName ?? AppStrings.notDetected),
        ],
      ),
    );
  }

  /// Builds the header row with network badge and validity indicator.
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildNetworkBadge(),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: details.isValid
                ? AppTheme.successColor.withAlpha(20)
                : AppTheme.errorColor.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                details.isValid
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 16,
                color: details.isValid
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
              const SizedBox(width: 4),
              Text(
                details.isValid ? AppStrings.validCard : AppStrings.invalidCard,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: details.isValid
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a network-coloured badge for Visa/MC/Amex/RuPay.
  Widget _buildNetworkBadge() {
    final color = _networkColor();
    final network = details.cardNetwork ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        network,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Returns a colour associated with the card network.
  Color _networkColor() {
    switch (details.cardNetwork) {
      case 'Visa':
        return AppTheme.visaBlue;
      case 'Mastercard':
        return AppTheme.mastercardOrange;
      case 'Amex':
        return AppTheme.amexBlue;
      case 'RuPay':
        return AppTheme.rupayOrange;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Builds a label + value field.
  Widget _buildField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: value == AppStrings.notDetected ? 0 : 1.2,
              ),
        ),
      ],
    );
  }
}
