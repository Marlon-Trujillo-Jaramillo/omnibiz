import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventario_app/core/design_system/design_system.dart';
import 'package:inventario_app/core/utils/date_formatter.dart';
import 'package:inventario_app/core/utils/money.dart';
import 'package:inventario_app/features/sales/presentation/providers/sales_notifier.dart';
import 'package:inventario_app/shared/providers/currency_provider.dart';

/// Ventas de los últimos 7 días (curva con área en degradado de marca).
class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final range = lastDaysRange(7);
    final salesAsync = ref.watch(salesInRangeProvider(range));
    final sales = salesAsync.valueOrNull ?? [];

    // Días calendario desde el inicio del rango (sin restar Duration: así un
    // cambio de horario no desplaza las etiquetas).
    final days = List.generate(7, (i) {
      final f = range.from;
      return DateTime(f.year, f.month, f.day + i);
    });
    final totals = [
      for (final d in days)
        sales
            .where(
              (s) =>
                  s.createdAt.year == d.year &&
                  s.createdAt.month == d.month &&
                  s.createdAt.day == d.day,
            )
            .fold(0, (sum, s) => sum + s.totalAmount),
    ];
    final spots = [
      for (var i = 0; i < 7; i++)
        FlSpot(i.toDouble(), Money.toMajor(totals[i])),
    ];
    final weekTotal = totals.fold(0, (a, b) => a + b);
    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return OmniCard(
      padding: const EdgeInsets.fromLTRB(
        OmniSpacing.base,
        OmniSpacing.base,
        OmniSpacing.base,
        OmniSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Últimos 7 días', style: context.text.label),
                    const SizedBox(height: OmniSpacing.xxs),
                    Text(
                      ref.formatMoney(weekTotal),
                      style: context.text.priceLg,
                    ),
                  ],
                ),
              ),
              OmniTag(
                label: '${sales.length} ventas',
                tone: OmniTone.brand,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: OmniSpacing.lg),
          LayoutBuilder(
            builder: (_, constraints) {
              final height = (constraints.maxWidth * 0.38).clamp(140.0, 220.0);
              if (salesAsync.isLoading && !salesAsync.hasValue) {
                return OmniSkeleton(height: height, radius: OmniRadius.md);
              }
              return SizedBox(
                height: height,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY == 0 ? 1 : maxY * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY == 0 ? 1 : maxY * 1.2 / 3,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: c.borderSubtle,
                        strokeWidth: OmniSizes.hairline,
                        dashArray: const [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => c.snackBg,
                        tooltipRoundedRadius: OmniRadius.sm,
                        getTooltipItems: (spots) => [
                          for (final s in spots)
                            LineTooltipItem(
                              ref.formatMoney(totals[s.x.toInt()]),
                              context.text.label
                                  .copyWith(color: c.onSnack)
                                  .tabular,
                            ),
                        ],
                      ),
                      getTouchedSpotIndicator: (_, idx) => [
                        for (final _ in idx)
                          TouchedSpotIndicatorData(
                            FlLine(color: c.borderWeak, strokeWidth: 1),
                            FlDotData(
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                    radius: 5,
                                    color: c.primary,
                                    strokeWidth: 2,
                                    strokeColor: c.bgSurface,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: OmniSpacing.xl,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) {
                              return const SizedBox.shrink();
                            }
                            final isToday = idx == days.length - 1;
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: OmniSpacing.sm,
                              ),
                              child: Text(
                                isToday
                                    ? 'Hoy'
                                    : DateFormatter.weekdayAbbr(
                                        days[idx].weekday,
                                      ),
                                style: context.text.caption.copyWith(
                                  color: isToday ? c.primaryText : c.textMuted,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        preventCurveOverShooting: true,
                        gradient: LinearGradient(
                          colors: [c.primary, c.brandEnd],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          checkToShowDot: (spot, _) => spot.x == 6,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                                radius: 4.5,
                                color: c.brandEnd,
                                strokeWidth: 2.5,
                                strokeColor: c.bgSurface,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              c.primary.withAlpha(c.isDark ? 70 : 45),
                              c.primary.withAlpha(0),
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
            },
          ),
        ],
      ),
    );
  }
}
