import 'package:flutter/material.dart';
import 'package:smart_reader/core/theme/app_theme.dart';
import 'package:smart_reader/core/constants/app_strings.dart';
import 'package:smart_reader/features/passbook_scanner/domain/models/bank_details.dart';

/// Displays the parsed bank passbook details in a styled result card.
class PassbookResultWidget extends StatelessWidget {
  /// The parsed bank details to display.
  final BankDetails details;

  /// Creates a [PassbookResultWidget].
  const PassbookResultWidget({super.key, required this.details});

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
          // Header with bank icon.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  details.bankName ?? 'Bank Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          _buildField(context, AppStrings.accountHolder,
              details.accountHolderName ?? AppStrings.notDetected),
          const SizedBox(height: 12),
          _buildField(context, AppStrings.accountNumber,
              details.maskedAccount ?? AppStrings.notDetected),
          const SizedBox(height: 12),
          _buildField(context, AppStrings.ifscCode,
              details.ifscCode ?? AppStrings.notDetected),
          if (details.bankName != null) ...[
            const SizedBox(height: 12),
            _buildField(context, AppStrings.bankName, details.bankName!),
          ],
        ],
      ),
    );
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
                letterSpacing: value == AppStrings.notDetected ? 0 : 0.8,
              ),
        ),
      ],
    );
  }
}
