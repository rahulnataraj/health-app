import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app_mobile/core/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/vitals/providers/vitals_provider.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

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
        final vitalsAsync = patientId != null
            ? ref.watch(vitalsHistoryProvider(patientId))
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
            title: Text('Diagnostics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: vitalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load vitals: $e')),
            data: (vitals) {
              if (vitals == null || (vitals is List && vitals.isEmpty)) {
                return const Center(child: Text('No vitals data available'));
              }

              final vitalList = vitals as List;
              // Reverse to get chronological order for chart
              final chronological = vitalList.reversed.toList();
              final latest = vitalList.first;

              // Build chart spots
              final spots = <FlSpot>[];
              for (int i = 0; i < chronological.length; i++) {
                spots.add(FlSpot(i.toDouble(), chronological[i].pulseRate.toDouble()));
              }

              // Calculate stats
              final pulseValues = chronological.map((v) => v.pulseRate).toList();
              final avgPulse = pulseValues.reduce((a, b) => a + b) / pulseValues.length;
              final maxPulse = pulseValues.reduce((a, b) => a > b ? a : b);
              final minPulse = pulseValues.reduce((a, b) => a < b ? a : b);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Card
                    Card(
                      color: AppColors.primaryLight,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.monitor_heart_rounded, color: AppColors.textMain, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Heartbeat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text('${vitalList.length} readings', style: theme.textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${latest.pulseRate}',
                                  style: theme.textTheme.displayMedium?.copyWith(
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('bpm', style: theme.textTheme.titleMedium),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: latest.status == 'critical'
                                        ? AppColors.criticalLight
                                        : latest.status == 'warning'
                                            ? AppColors.warningLight
                                            : AppColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    latest.statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: latest.status == 'critical'
                                          ? AppColors.critical
                                          : latest.status == 'warning'
                                              ? AppColors.warning
                                              : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Real Line Chart
                            SizedBox(
                              height: 150,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: 20,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.white.withOpacity(0.3),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 32,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                                          );
                                        },
                                      ),
                                    ),
                                    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minY: (minPulse - 10).toDouble(),
                                  maxY: (maxPulse + 10).toDouble(),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: AppColors.primary,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          final vital = chronological[index];
                                          final dotColor = vital.status == 'critical'
                                              ? AppColors.critical
                                              : vital.status == 'warning'
                                                  ? AppColors.warning
                                                  : AppColors.primary;
                                          return FlDotCirclePainter(
                                            radius: 3,
                                            color: dotColor,
                                            strokeWidth: 1,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: AppColors.primary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(theme, 'Average', '${avgPulse.toStringAsFixed(0)} bpm', AppColors.primaryLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(theme, 'Max', '$maxPulse bpm', AppColors.warningLight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(theme, 'Min', '$minPulse bpm', AppColors.successLight),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Recent readings list
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent Readings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...vitalList.take(10).map((vital) {
                              final statusColor = vital.status == 'critical'
                                  ? AppColors.critical
                                  : vital.status == 'warning'
                                      ? AppColors.warning
                                      : AppColors.success;

                              final timeStr = DateFormat('MMM d, HH:mm').format(vital.createdAt);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${vital.pulseRate} bpm',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      vital.statusLabel,
                                      style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(timeStr, style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, Color bgColor) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
