import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Standard Loading View for all menus
class AppLoadingView extends StatelessWidget {
  final String message;
  final Color? color;

  const AppLoadingView({
    super.key,
    this.message = 'Memuat data...',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard Empty View for menus with no data
class AppEmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyView({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard Error View for network, Firestore rules, or permission failures
class AppErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.title = 'Terjadi Kendala Jaringan / Izin',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Coba Lagi',
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppColors.dangerRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade800,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
