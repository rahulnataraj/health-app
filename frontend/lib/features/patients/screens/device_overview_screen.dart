import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app_mobile/core/theme/app_theme.dart';
import 'package:health_app_mobile/shared_widgets/custom_bottom_nav.dart';
import 'package:health_app_mobile/shared_widgets/custom_avatar.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/vitals/providers/vitals_provider.dart';
import 'package:health_app_mobile/features/patients/providers/patient_provider.dart';

class DeviceOverviewScreen extends ConsumerWidget {
  const DeviceOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          // Not logged in
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
                        child: Stack(
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 28),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'Tracking\nyour heart',
                    style: theme.textTheme.displaySmall?.copyWith(height: 1.1, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 32),

                  // Patient Info + Latest Pulse
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Latest Pulse Card
                      Expanded(
                        flex: 2,
                        child: latestVitalAsync.when(
                          loading: () => Card(
                            color: AppColors.highlightLight,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          ),
                          error: (e, _) => Card(
                            color: AppColors.criticalLight,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error loading vitals', style: theme.textTheme.bodySmall),
                            ),
                          ),
                          data: (vital) {
                            final pulse = vital?.pulseRate ?? '--';
                            final status = vital?.status ?? 'normal';
                            final cardColor = status == 'critical'
                                ? AppColors.criticalLight
                                : status == 'warning'
                                    ? AppColors.warningLight
                                    : AppColors.highlightLight;
                            final iconColor = status == 'critical'
                                ? AppColors.critical
                                : status == 'warning'
                                    ? AppColors.warning
                                    : AppColors.highlight;

                            return Card(
                              color: cardColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                child: Column(
                                  children: [
                                    Text(
                                      '$pulse',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: AppColors.textMain,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('bpm', style: theme.textTheme.bodySmall),
                                    const SizedBox(height: 16),
                                    Icon(Icons.favorite_rounded, color: iconColor, size: 32),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        vital?.statusLabel ?? 'N/A',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right: Patient Info Card
                      Expanded(
                        flex: 3,
                        child: patientAsync.when(
                          loading: () => Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (e, _) => Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: AppColors.criticalLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(child: Text('Error', style: theme.textTheme.bodySmall)),
                          ),
                          data: (patient) {
                            return Container(
                              height: 220,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primaryLight, AppColors.successLight],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_outline, color: AppColors.primary, size: 28),
                                    const SizedBox(height: 12),
                                    Text(
                                      patient?.name ?? 'Patient',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Age: ${patient?.age ?? '--'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (patient?.medicalCondition != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          patient!.medicalCondition!,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Connect to Monitoring Button
                  Card(
                    color: AppColors.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.monitor_heart_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live\nMonitoring',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward, color: AppColors.textMain),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connect Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.highlightLight,
                        foregroundColor: AppColors.textMain,
                      ),
                      onPressed: () => context.go('/monitoring'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.sensors),
                          Text('Connect   >>>'),
                          Icon(Icons.sensors),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 1) context.go('/monitoring');
              if (index == 2) context.go('/analytics');
              if (index == 3) context.go('/alerts');
            },
          ),
        );
      },
    );
  }
}
