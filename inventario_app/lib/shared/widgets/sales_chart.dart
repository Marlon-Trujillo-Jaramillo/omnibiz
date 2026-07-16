import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/date_formatter.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final sales = salesAsync.valueOrNull ?? [];
    final now = DateTime.now();

    final spots = List.generate(7, (i) {
      final date  = now.subtract(Duration(days: 6 - i));
      final total = sales
          .where((s) =>
              s.createdAt.year == date.year &&
              s.createdAt.month == date.month &&
              s.createdAt.day == date.day)
          .fold(0.0, (sum, s) => sum + s.totalAmount);
      return FlSpot(i.toDouble(), total);
    });

    final weekTotal = sales
        .where((s) => s.createdAt.isAfter(now.subtract(const Duration(days: 7))))
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    final dayLabels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateFormatter.weekdayAbbr(date.weekday);
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base,
        OmniSpacing.lg,
        OmniSpacing.base,
        OmniSpacing.md,
      ),
      decoration: BoxDecoration(
        color: OmniColors.bgSurface,
        borderRadius: OmniRadius.xxlAll,
        border: Border.all(color: OmniColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ventas — últimos 7 días', style: OmniTypography.label),
              Text(
                ref.formatMoney(weekTotal),
                style: OmniTypography.headingSm
                    .copyWith(color: OmniColors.primary),
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.base),
          LayoutBuilder(builder: (_, constraints) {
            final height = (constraints.maxWidth * 0.35).clamp(120.0, 200.0);
            return SizedBox(
              height: height,
              child: LineChart(
              LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(dayLabels[idx],
                              style: OmniTypography.caption),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [OmniColors.primary, OmniColors.purple],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          OmniColors.primary.withAlpha(40),
                          OmniColors.purple.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          }),
        ],
      ),
    );
  }
}
