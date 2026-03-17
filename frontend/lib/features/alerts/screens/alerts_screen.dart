import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app_mobile/core/theme/app_theme.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
          return const SizedBox.shrink();
        }

        final patientId = user.patientId;
        final alertsAsync = patientId != null
            ? ref.watch(alertsProvider(patientId))
            : const AsyncValue<dynamic>.data(null);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain),
              onPressed: () => context.go('/device-overview'),
            ),
            title: Text('Alerts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: alertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.critical),
                  const SizedBox(height: 16),
                  Text('Failed to load alerts', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            data: (alerts) {
              if (alerts == null || (alerts is List && alerts.isEmpty)) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('All Clear', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('No alerts at this time', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              final alertList = alerts as List;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alertList.length,
                itemBuilder: (context, index) {
                  final alert = alertList[index];
                  final isRead = alert.isRead;

                  Color severityColor;
                  IconData severityIcon;
                  Color bgColor;

                  switch (alert.severity) {
                    case 'critical':
                      severityColor = AppColors.critical;
                      severityIcon = Icons.warning_amber_rounded;
                      bgColor = AppColors.criticalLight;
                      break;
                    case 'warning':
                      severityColor = AppColors.warning;
                      severityIcon = Icons.info_outline;
                      bgColor = AppColors.warningLight;
                      break;
                    default:
                      severityColor = AppColors.primary;
                      severityIcon = Icons.notifications_outlined;
                      bgColor = AppColors.primaryLight;
                  }

                  final timeStr = DateFormat('MMM d, HH:mm').format(alert.createdAt);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: isRead ? AppColors.surface : bgColor,
                      elevation: isRead ? 1 : 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(severityIcon, color: severityColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: severityColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          alert.severity.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: severityColor,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    alert.message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textMain,
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                    ),
                                  ),
                                  if (alert.pulseRate != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pulse: ${alert.pulseRate} bpm',
                                      style: theme.textTheme.bodySmall?.copyWith(color: severityColor),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
