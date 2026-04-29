import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../services/chat_service.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  bool _loading = true;
  List<dynamic> _trends = [];

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    try {
      final trends = await ChatService.getStressTrends();
      setState(() {
        _trends = trends;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _getStressLabel(int score) {
    if (score <= 3) return "Low";
    if (score <= 7) return "Medium";
    return "High";
  }

  Color _getStressColor(int score) {
    if (score <= 3) return Colors.green.shade400;
    if (score <= 7) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: const Text(
          "Your Trends",
          style: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trends.isEmpty
              ? const Center(
                  child: Text(
                    "No data available yet.\nChat to start tracking!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Recent Stress Levels",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Automatically tracked from your conversations.",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 40),
                      
                      // 📊 Chart
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10,
                              minY: 0,
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < _trends.length) {
                                        return Text(
                                          "Day ${index + 1}",
                                          style: const TextStyle(fontSize: 12),
                                        );
                                      }
                                      return const Text("");
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 3.3,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 2) return const Text("Low", style: TextStyle(fontSize: 10));
                                      if (value == 5) return const Text("Med", style: TextStyle(fontSize: 10));
                                      if (value == 8) return const Text("High", style: TextStyle(fontSize: 10));
                                      return const Text("");
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(
                                _trends.length,
                                (index) {
                                  final score = _trends[index]["stress_score"] as int? ?? 5;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: score.toDouble(),
                                        color: _getStressColor(score),
                                        width: 16,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // 💡 Insights
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insights, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your latest interaction showed ${_getStressLabel(_trends.last['stress_score'] ?? 5).toLowerCase()} stress levels. Keep taking care of yourself 💙",
                                style: const TextStyle(color: AppColors.textDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}
