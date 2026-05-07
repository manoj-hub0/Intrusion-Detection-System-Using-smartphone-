import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'feature_extractor.dart';
import 'ids_api.dart';

void main() {
  runApp(const HybridIDSApp());
}

class HybridIDSApp extends StatelessWidget {
  const HybridIDSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid IDS',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Change this to your PC IP when running on a real phone:
  // e.g. http://192.168.0.10:8000
  final api = IDSApi(baseUrl: 'http://127.0.0.1:8000');

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _ax = 0, _ay = 0, _az = 0;
  double _gx = 0, _gy = 0, _gz = 0;

  final List<Map<String, double>> _buffer = [];
  final int windowSize = 50;
  final int step = 25;

  bool _running = false;
  String _status = 'Idle';
  double _p = 0.0;
  double _score = 0.0;
  bool _gated = false;

  Timer? _timer;

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _status = 'Collecting...';
    });

    _accelSub = accelerometerEvents.listen((e) {
      _ax = e.x;
      _ay = e.y;
      _az = e.z;
    });

    _gyroSub = gyroscopeEvents.listen((e) {
      _gx = e.x;
      _gy = e.y;
      _gz = e.z;
    });

    // Sample at ~20Hz (50ms). Adjust if needed.
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      if (!_running) return;
      _buffer.add({'ax': _ax, 'ay': _ay, 'az': _az, 'gx': _gx, 'gy': _gy, 'gz': _gz});

      if (_buffer.length >= windowSize) {
        final window = _buffer.sublist(_buffer.length - windowSize);
        final feats = FeatureExtractor.extract(window);

        try {
          final res = await api.predict(feats);
          setState(() {
            _score = (res['anomaly_score'] as num).toDouble();
            _gated = (res['gated'] as bool);
            _p = (res['intrusion_probability'] as num).toDouble();
            final pred = (res['prediction'] as num).toInt();
            _status = pred == 1 ? 'INTRUSION DETECTED' : 'Normal';
          });
        } catch (e) {
          setState(() {
            _status = 'API error: $e';
          });
        }

        // Slide window by step (keep recent samples)
        if (_buffer.length > windowSize + step) {
          _buffer.removeRange(0, _buffer.length - windowSize);
        }
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    setState(() {
      _running = false;
      _status = 'Stopped';
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIntrusion = _status == 'INTRUSION DETECTED';
    return Scaffold(
      appBar: AppBar(title: const Text('Hybrid IDS (Sensors)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $_status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Anomaly score: ${_score.toStringAsFixed(4)} (gated: $_gated)'),
                    Text('Intrusion probability: ${_p.toStringAsFixed(4)}'),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _p.clamp(0.0, 1.0)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Sensors', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Accel: x=${_ax.toStringAsFixed(3)}  y=${_ay.toStringAsFixed(3)}  z=${_az.toStringAsFixed(3)}'),
                      Text('Gyro : x=${_gx.toStringAsFixed(3)}  y=${_gy.toStringAsFixed(3)}  z=${_gz.toStringAsFixed(3)}'),
                      const Spacer(),
                      Text('Window: $windowSize samples | Step: $step samples'),
                      Text('API Base URL: ${api.baseUrl}'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _running ? null : _start,
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _running ? _stop : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: When testing on a physical phone, set baseUrl to your PC IP (same Wi‑Fi), e.g. http://192.168.0.10:8000',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
