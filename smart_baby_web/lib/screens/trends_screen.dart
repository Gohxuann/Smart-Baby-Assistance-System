import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('babydata');
  double distanceThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    fetchTrends();

    _dbRef.child('distance_threshold').onValue.listen((event) {
      final rawValue = event.snapshot.value?.toString() ?? '10.0';
      final parsed = double.tryParse(rawValue);
      if (parsed != null) {
        setState(() {
          distanceThreshold = parsed;
        });
      }
    });
  }

  Future<void> fetchTrends() async {
    const url = 'http://smartbabysystem.threelittlecar.com/get_data.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        records = data.cast<Map<String, dynamic>>().reversed.toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  List<FlSpot> _getSpots(String key) {
    List<FlSpot> spots = [];
    for (int i = 0; i < records.length; i++) {
      final value = double.tryParse(records[i][key]?.toString() ?? '0') ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  List<String> _getTimestamps() {
    return records.map((r) {
      final timestamp = r['timestamp']?.toString() ?? '';
      return timestamp.length >= 16 ? timestamp.substring(11, 16) : '';
    }).toList();
  }

  Widget _buildDistanceChart(double threshold) {
    final timestamps = _getTimestamps();
    return _buildGlassCard(
      "Distance (cm)",
      SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          minY: 0,
          maxY: 200,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 50,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int i = value.toInt();
                  if (i < 0 || i >= timestamps.length) return const Text('');
                  return Text(
                    timestamps[i],
                    style: const TextStyle(fontSize: 10),
                  );
                },
                interval: (timestamps.length / 6).ceilToDouble(),
                reservedSize: 24,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _getSpots("dist"),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: barData.color ?? Colors.black,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.3),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: threshold,
              color: Colors.red,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(color: Colors.red, fontSize: 10),
                labelResolver: (_) => 'Threshold',
              ),
            )
          ]),
        )),
      ),
    );
  }

  Widget _buildLineChart(String title, String key, Color color) {
    final timestamps = _getTimestamps();
    return _buildGlassCard(
      title,
      Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int i = value.toInt();
                      if (i < 0 || i >= timestamps.length) {
                        return const Text('');
                      }
                      return Text(
                        timestamps[i],
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    interval: (timestamps.length / 6).ceilToDouble(),
                    reservedSize: 24,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _getSpots(key),
                  isCurved: true,
                  color: color,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: barData.color ?? Colors.black,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.2),
                  ),
                ),
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, String key) {
    Map<String, int> counts = {};
    for (var r in records) {
      final val = r[key]?.toString().toUpperCase() ?? 'NO';
      counts[val] = (counts[val] ?? 0) + 1;
    }
    return _buildGlassCard(
      title,
      SizedBox(
        height: 200,
        child: BarChart(BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  if (v == 0) return const Text('NO');
                  if (v == 1) return const Text('YES');
                  return const Text('');
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                toY: (counts['NO'] ?? 0).toDouble(),
                color: Colors.red,
              )
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                toY: (counts['YES'] ?? 0).toDouble(),
                color: Colors.green,
              )
            ]),
          ],
        )),
      ),
    );
  }

  Widget _buildAwakeTrendChart() {
    Map<String, int> hourMap = {};
    for (var r in records) {
      if ((r['status'] ?? '').toLowerCase().contains("wake")) {
        final time = DateTime.tryParse(r['timestamp'] ?? '') ?? DateTime.now();
        final hour = '${time.hour.toString().padLeft(2, '0')}:00';
        hourMap[hour] = (hourMap[hour] ?? 0) + 1;
      }
    }
    final sortedHours = hourMap.keys.toList()..sort();
    return _buildGlassCard(
      "Awake Frequency by Hour",
      SizedBox(
        height: 250,
        child: BarChart(BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i < 0 || i >= sortedHours.length) return const Text('');
                  return Text(
                    sortedHours[i],
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(sortedHours.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: hourMap[sortedHours[i]]!.toDouble(),
                color: Colors.orange,
              )
            ]);
          }),
        )),
      ),
    );
  }

  Widget _buildGlassCard(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.3)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(4, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black)),
          const SizedBox(height: 8),
          child
        ],
      ),
    );
  }

  Widget _buildPeriodActivityChart({
    required String title,
    required String key,
    required Color color,
  }) {
    final Map<String, int> sectionCounts = {
      "Early Morning": 0,
      "Morning": 0,
      "Afternoon": 0,
      "Evening": 0,
      "Night": 0,
    };

    for (var r in records) {
      final timestampStr = r['timestamp'];
      final status = r[key]?.toString().toUpperCase() ?? 'NO';
      if (timestampStr == null || status != 'YES') continue;

      final dt = DateTime.tryParse(timestampStr);
      if (dt == null) continue;

      final now = DateTime.now();
      if (dt.year != now.year || dt.month != now.month || dt.day != now.day) {
        continue; // only today's data
      }

      final hour = dt.hour;
      String section;
      if (hour < 6) {
        section = "Early Morning";
      } else if (hour < 12) {
        section = "Morning";
      } else if (hour < 16) {
        section = "Afternoon";
      } else if (hour < 20) {
        section = "Evening";
      } else {
        section = "Night";
      }

      sectionCounts[section] = sectionCounts[section]! + 1;
    }

    final sections = [
      "Early Morning",
      "Morning",
      "Afternoon",
      "Evening",
      "Night"
    ];

    return _buildGlassCard(
      "$title YES Count by Time of Day (Today)",
      SizedBox(
        height: 250,
        child: BarChart(BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  int i = v.toInt();
                  if (i < 0 || i >= sections.length) return const Text('');
                  return Text(
                    sections[i],
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          barGroups: List.generate(sections.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: sectionCounts[sections[i]]!.toDouble(),
                color: color,
              )
            ]);
          }),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      appBar: AppBar(
        title: const Text("📈 Trends"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLineChart("Temperature Over Time", "temp", Colors.red),
                  _buildDistanceChart(100),
                  _buildAwakeTrendChart(),
                  _buildPeriodActivityChart(
                    title: "Vibration",
                    key: "vibrate",
                    color: Colors.purple,
                  ),
                  _buildPeriodActivityChart(
                    title: "Motion",
                    key: "motion",
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
    );
  }
}
