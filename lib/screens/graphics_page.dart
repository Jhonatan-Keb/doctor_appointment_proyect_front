// lib/screens/graphics_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphicsPage extends StatelessWidget {
  const GraphicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión como médico para ver las gráficas'),
        ),
      );
    }

    // Todas las citas de ESTE médico
    final citasStream = FirebaseFirestore.instance
        .collection('citas')
        .where('medicoId', isEqualTo: user.uid)
        .snapshots();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficas del Médico'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: citasStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar datos: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final now = DateTime.now();

          // ========= 1) Citas por mes del año actual =========
          final List<int> citasPorMes = List<int>.filled(12, 0);

          // ========= 2) Citas en los últimos 7 días =========
          // Ventana: hoy-6, hoy-5, ..., hoy
          final DateTime start7 =
              DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 6),
          );
          final List<int> citasUltimos7Dias = List<int>.filled(7, 0);

          // ========= 3) Estados de las citas =========
          int pendientes = 0;
          int completadas = 0;
          int canceladas = 0;

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            // ----- Fecha -----
            final ts = data['cuando'] as Timestamp?;
            if (ts != null) {
              final fecha = ts.toDate();

              // Citas por mes del año actual
              if (fecha.year == now.year) {
                final idxMes = fecha.month - 1;
                if (idxMes >= 0 && idxMes < 12) {
                  citasPorMes[idxMes]++;
                }
              }

              // Citas en los últimos 7 días (pasado + hoy)
              final normalized = DateTime(fecha.year, fecha.month, fecha.day);
              final diffDays = normalized.difference(start7).inDays;
              if (diffDays >= 0 && diffDays < 7) {
                citasUltimos7Dias[diffDays]++;
              }
            }

            // ----- Estado -----
            final estado =
                (data['estado'] ?? 'pendiente').toString().toLowerCase();

            if (estado.contains('comp')) {
              completadas++;
            } else if (estado.contains('cancel')) {
              canceladas++;
            } else {
              pendientes++;
            }
          }

          final totalCitas = docs.length;
          final totalSemana =
              citasUltimos7Dias.fold<int>(0, (sum, v) => sum + v);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen visual de tus citas',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los datos se obtienen en tiempo real desde Firebase Cloud Firestore.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ============== GRÁFICA 1: BARRAS POR MES ==============
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Citas creadas por mes (${now.year})',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Muestra cuántas citas tienes registradas en cada mes del año actual.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: BarChart(
                              _buildBarChartData(citasPorMes, theme),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============== GRÁFICA 2: LÍNEA ÚLTIMOS 7 DÍAS ==============
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Citas en los últimos 7 días',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Permite ver el comportamiento diario reciente de tus citas.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: totalSemana == 0
                                ? Center(
                                    child: Text(
                                      'No se han registrado citas en los últimos 7 días.\n\n'
                                      'Si ya tienes citas, verifica que la fecha esté dentro de la última semana '
                                      'y que el campo "cuando" sea un Timestamp válido.',
                                      style: theme.textTheme.bodySmall,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : LineChart(
                                    _buildLineChartData(
                                      citasUltimos7Dias,
                                      theme,
                                      start7,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============== GRÁFICA 3: PIE ESTADO DE CITAS ==============
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado de las citas',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comparación entre citas pendientes, completadas y canceladas.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 260,
                            child: PieChart(
                              _buildPieChartData(
                                pendientes: pendientes,
                                completadas: completadas,
                                canceladas: canceladas,
                                theme: theme,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _LegendDot(
                                color: theme.colorScheme.primary,
                                label: 'Pendientes ($pendientes)',
                              ),
                              _LegendDot(
                                color: Colors.teal,
                                label: 'Completadas ($completadas)',
                              ),
                              _LegendDot(
                                color: Colors.redAccent,
                                label: 'Canceladas ($canceladas)',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============== CONFIG GRÁFICA 1: BARRAS POR MES ==============

  BarChartData _buildBarChartData(List<int> citasPorMes, ThemeData theme) {
    final maxY =
        (citasPorMes.reduce((a, b) => a > b ? a : b)).toDouble();
    final safeMaxY = maxY == 0 ? 1.0 : maxY + 1;

    final monthLabels = <int, String>{
      0: 'Ene',
      1: 'Feb',
      2: 'Mar',
      3: 'Abr',
      4: 'May',
      5: 'Jun',
      6: 'Jul',
      7: 'Ago',
      8: 'Sep',
      9: 'Oct',
      10: 'Nov',
      11: 'Dic',
    };

    return BarChartData(
      maxY: safeMaxY,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              final label = monthLabels[index] ?? '';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      barGroups: List.generate(12, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: citasPorMes[index].toDouble(),
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      }),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final monthLabels = <int, String>{
              0: 'Ene',
              1: 'Feb',
              2: 'Mar',
              3: 'Abr',
              4: 'May',
              5: 'Jun',
              6: 'Jul',
              7: 'Ago',
              8: 'Sep',
              9: 'Oct',
              10: 'Nov',
              11: 'Dic',
            };
            final month = monthLabels[group.x.toInt()] ?? '';
            final count = rod.toY.toInt();
            return BarTooltipItem(
              '$month\n$count citas',
              TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== CONFIG GRÁFICA 2: LÍNEA ÚLTIMOS 7 DÍAS ==============

  LineChartData _buildLineChartData(
    List<int> citasUltimos7Dias,
    ThemeData theme,
    DateTime startDate,
  ) {
    final maxY =
        (citasUltimos7Dias.reduce((a, b) => a > b ? a : b)).toDouble();
    final safeMaxY = maxY == 0 ? 1.0 : maxY + 1;

    final spots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), citasUltimos7Dias[i].toDouble()));
    }

    return LineChartData(
      minX: 0,
      maxX: 6,
      minY: 0,
      maxY: safeMaxY,
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              return Text(
                value.toInt().toString(),
                style: theme.textTheme.bodySmall,
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index > 6) {
                return const SizedBox.shrink();
              }
              final d = startDate.add(Duration(days: index));
              final label = '${d.day}/${d.month}';
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          dotData: FlDotData(show: true),
          // color llamativo para que se vea bien en tema oscuro
          color: theme.colorScheme.secondary,
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              final date = startDate.add(Duration(days: index));
              final label = '${date.day}/${date.month}';
              final count = barSpot.y.toInt();
              return LineTooltipItem(
                '$label\n$count citas',
                TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // ============== CONFIG GRÁFICA 3: PIE ESTADO ==============

  PieChartData _buildPieChartData({
    required int pendientes,
    required int completadas,
    required int canceladas,
    required ThemeData theme,
  }) {
    final total = pendientes + completadas + canceladas;
    final sections = <PieChartSectionData>[];

    double percent(int value) =>
        total == 0 ? 0 : (value * 100 / total);

    if (pendientes > 0) {
      sections.add(
        PieChartSectionData(
          value: pendientes.toDouble(),
          title: '${percent(pendientes).toStringAsFixed(0)}%',
          color: theme.colorScheme.primary,
          radius: 70,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (completadas > 0) {
      sections.add(
        PieChartSectionData(
          value: completadas.toDouble(),
          title: '${percent(completadas).toStringAsFixed(0)}%',
          color: Colors.teal,
          radius: 70,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (canceladas > 0) {
      sections.add(
        PieChartSectionData(
          value: canceladas.toDouble(),
          title: '${percent(canceladas).toStringAsFixed(0)}%',
          color: Colors.redAccent,
          radius: 70,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: 'Sin datos',
          color: theme.colorScheme.surfaceVariant,
          radius: 60,
          titleStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      borderData: FlBorderData(show: false),
    );
  }
}

// ============== WIDGET PARA LEYENDA ==============

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
