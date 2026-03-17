import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app_mobile/core/theme/app_theme.dart';
import 'package:health_app_mobile/shared_widgets/custom_bottom_nav.dart';
import 'package:health_app_mobile/shared_widgets/custom_avatar.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/vitals/providers/vitals_provider.dart';
import 'package:health_app_mobile/features/patients/providers/patient_provider.dart';

class MonitoringDashboardScreen extends ConsumerWidget {
  const MonitoringDashboardScreen({super.key});

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
        final latestVitalAsync = patientId != null
            ? ref.watch(latestVitalProvider(patientId))
            : const AsyncValue<dynamic>.data(null);
        final patientAsync = patientId != null
            ? ref.watch(patientProvider(patientId))
            : const AsyncValue<dynamic>.data(null);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CustomAvatar(
                            imageUrl: 'https://i.pravatar.cc/150?img=11',
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.username}!',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/alerts'),
                        child: const Icon(Icons.notifications_none_rounded, size: 28),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Heart Health',
                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 24),

                  // Main Health Card
                  latestVitalAsync.when(
                    loading: () => Card(
                      color: AppColors.successLight,
                      child: const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                    error: (e, _) => Card(
                      color: AppColors.criticalLight,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Failed to load vitals', style: theme.textTheme.bodyMedium),
                      ),
                    ),
                    data: (vital) {
                      final status = vital?.status ?? 'normal';
                      final bgColor = status == 'critical'
                          ? AppColors.criticalLight
                          : status == 'warning'
                              ? AppColors.warningLight
                              : AppColors.successLight;
                      final iconColor = status == 'critical'
                          ? AppColors.critical
                          : status == 'warning'
                              ? AppColors.warning
                              : AppColors.success;

                      return Card(
                        color: bgColor,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.favorite_outline, color: iconColor),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      vital?.statusLabel ?? 'No Data',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pulse: ${vital?.pulseRate ?? '--'} bpm',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textMain.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: iconColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        vital?.statusLabel ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Large pulse display
                              Container(
                                width: 120,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monitor_heart, size: 40, color: iconColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${vital?.pulseRate ?? '--'}',
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'bpm',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Metric Tiles
                  latestVitalAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (vital) => Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            title: 'Pulse Rate',
                            value: '${vital?.pulseRate ?? '--'}',
                            subvalue: ' bpm',
                            iconData: Icons.favorite_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricTile(
                            context,
                            title: 'Status',
                            value: vital?.statusLabel ?? 'N/A',
                            subvalue: '',
                            iconData: Icons.health_and_safety,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Patient Info Card
                  patientAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (patient) => Card(
                      color: AppColors.highlightLight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const CustomAvatar(imageUrl: 'https://i.pravatar.cc/150?img=33', radius: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient?.name ?? 'Patient',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    patient?.medicalCondition ?? 'Under monitoring',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.analytics_outlined, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) context.go('/device-overview');
              if (index == 2) context.go('/analytics');
              if (index == 3) context.go('/alerts');
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(BuildContext context, {
    required String title,
    required String value,
    required String subvalue,
    required IconData iconData,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: AppColors.textMain, size: 24),
            const SizedBox(height: 24),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: value),
                  TextSpan(text: subvalue, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
