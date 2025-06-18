import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'login_screen.dart';
import 'package:smart_baby_web/screens/trends_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('babydata');

  String temp = 'Loading...';
  String hum = 'Loading...';
  String dist = 'Loading...';
  String status = 'Loading...';
  String safety = 'Loading...';
  String relay = 'Loading...';
  String lastActive = 'Loading...';
  String awakeDuration = 'Loading...';
  String mode = 'auto';
  String manualRelay = 'OFF';
  String motion = 'Loading...';
  String vibration = 'Loading...';
  String dangerNear = 'Loading...';
  double distanceThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _dbRef.onValue.listen((event) {
        //print("RAW SNAPSHOT: ${event.snapshot.value}");
        final raw = event.snapshot.value;
        if (raw is Map) {
          final data = raw;
          setState(() {
            temp = data['temp']?.toStringAsFixed(1) ?? '0.0';
            hum = data['hum']?.toStringAsFixed(1) ?? '0.0';
            dist = data['dist']?.toStringAsFixed(1) ?? '0.0';
            status = data['status'] ?? 'Unknown';
            safety = data['safety'] ?? 'Unknown';
            lastActive = data['last_active'] ?? 'N/A';
            awakeDuration = '${data['awake_duration_sec'] ?? 0}s';
            relay = data['relay'] ?? 'Unknown';
            mode = data['mode'] ?? 'auto';
            manualRelay = data['manual_relay'] ?? 'OFF';
            motion = data['motion'] ?? 'Unknown';
            vibration = data['vibrate'] ?? 'Unknown';
            dangerNear = data['dangerNear'] ?? 'Unknown';
            distanceThreshold =
                double.tryParse(data['distance_threshold']?.toString() ?? '') ??
                    10.0;
          });
        } else {
          //print("Unexpected data format received from Firebase.");
        }
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> confirmModeChange(String newMode) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Mode Change'),
        content: Text('Are you sure you want to switch to "$newMode" mode?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      _dbRef.update({'mode': newMode});
    }
  }

  Future<void> confirmRelayToggle(bool isOn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Alarm Toggle'),
        content: Text(
            'Are you sure you want to turn ${isOn ? 'ON' : 'OFF'} the alarm manually?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      _dbRef.update({'manual_relay': isOn ? 'ON' : 'OFF'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFB3E5FC),
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'View Trends',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrendsScreen()),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text("Smart Baby Assistance System",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Logged in as: ${currentUser?.email ?? 'Unknown'}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                width: 250,
                child: Lottie.asset('assets/lottie/baby.json'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildGlassCard("🌍 Surrounding", [
                      _buildInfoCard(
                          "🌡️ Temperature",
                          '$temp °C',
                          double.tryParse(temp) != null &&
                                  double.parse(temp) > 30
                              ? Colors.red
                              : Colors.green),
                      _buildInfoCard("💧 Humidity", '$hum %', Colors.blue),
                      _buildInfoCard(
                          "📏 Distance",
                          '$dist cm',
                          double.tryParse(dist) != null &&
                                  double.parse(dist) < 10
                              ? Colors.red
                              : Colors.green),
                      _buildInfoCard("🎯 Motion", motion, Colors.purple),
                      _buildInfoCard("💥 Vibration", vibration, Colors.indigo),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGlassCard("📊 Condition", [
                      _buildInfoCard("👶 Status", status,
                          status == "Baby Wakeup!" ? Colors.red : Colors.green),
                      _buildInfoCard("🛡️ Safety", safety,
                          safety == "Too near!" ? Colors.red : Colors.green),
                      _buildInfoCard(
                          "🕒 Awake Duration", awakeDuration, Colors.orange),
                      _buildInfoCard("📶 Too Near Triggered", dangerNear,
                          dangerNear == 'YES' ? Colors.red : Colors.green),
                      _buildInfoCard("⏰ Last Active", lastActive, Colors.grey),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildGlassCard("🛠️ Parent Control Panel", [
                _buildInfoCard("🚨 Alarm", relay,
                    relay == "ON" ? Colors.red : Colors.green),
                _buildInfoCard("📏 Distance Threshold",
                    "${distanceThreshold.toStringAsFixed(1)} cm", Colors.teal),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.teal,
                    inactiveTrackColor: Colors.teal.shade100,
                    thumbColor: Colors.teal,
                    overlayColor: Colors.teal.withAlpha(32),
                  ),
                  child: Slider(
                    value: distanceThreshold,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    label: "${distanceThreshold.toStringAsFixed(1)} cm",
                    onChanged: (value) {
                      setState(() {
                        distanceThreshold = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _dbRef.update({'distance_threshold': value});
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Control Mode:", style: TextStyle(fontSize: 16)),
                    DropdownButton<String>(
                      value: mode,
                      items: ['auto', 'manual']
                          .map((value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'auto'
                                    ? '🤖 AUTO'
                                    : '🧑‍🔧 MANUAL'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null && value != mode) {
                          confirmModeChange(value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (mode == 'manual')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Manual Relay:",
                          style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Text(manualRelay == 'ON' ? '🔴 ON' : '🟢 OFF',
                              style: const TextStyle(fontSize: 16)),
                          Switch(
                            value: manualRelay == 'ON',
                            onChanged: (val) {
                              confirmRelayToggle(val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
              ]),
              const SizedBox(height: 10),
              const Text("Created by Goh Hong Xuan",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(String title, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.3),
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
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, color: Colors.black)),
          Text(value,
              style: TextStyle(
                  fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
