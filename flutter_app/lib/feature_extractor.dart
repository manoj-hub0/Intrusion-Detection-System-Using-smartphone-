import 'dart:math';

class FeatureExtractor {
  // Computes basic stats for a list of doubles
  static Map<String, double> _stats(String name, List<double> v) {
    if (v.isEmpty) {
      return {
        '${name}__mean': 0.0,
        '${name}__std': 0.0,
        '${name}__min': 0.0,
        '${name}__max': 0.0,
        '${name}__median': 0.0,
        '${name}__energy': 0.0,
      };
    }
    double sum = 0.0;
    double sumsq = 0.0;
    double mn = v.first;
    double mx = v.first;
    for (final x in v) {
      sum += x;
      sumsq += x * x;
      if (x < mn) mn = x;
      if (x > mx) mx = x;
    }
    final mean = sum / v.length;
    // population std
    double varSum = 0.0;
    for (final x in v) {
      final d = x - mean;
      varSum += d * d;
    }
    final std = sqrt(varSum / v.length);

    final sorted = List<double>.from(v)..sort();
    final mid = sorted.length ~/ 2;
    final median = (sorted.length % 2 == 1)
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2.0;

    return {
      '${name}__mean': mean,
      '${name}__std': std,
      '${name}__min': mn,
      '${name}__max': mx,
      '${name}__median': median,
      '${name}__energy': sumsq,
    };
  }

  static double _corr(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    final n = a.length;
    double meanA = 0.0, meanB = 0.0;
    for (int i = 0; i < n; i++) {
      meanA += a[i];
      meanB += b[i];
    }
    meanA /= n;
    meanB /= n;

    double num = 0.0;
    double denA = 0.0;
    double denB = 0.0;
    for (int i = 0; i < n; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      num += da * db;
      denA += da * da;
      denB += db * db;
    }
    final denom = sqrt(denA * denB);
    if (denom == 0.0) return 0.0;
    return num / denom;
  }

  /// Extract features from a window of accelerometer + gyroscope samples.
  /// Each sample should contain keys:
  ///  - ax, ay, az
  ///  - gx, gy, gz
  static Map<String, double> extract(List<Map<String, double>> window) {
    final ax = <double>[]; final ay = <double>[]; final az = <double>[];
    final gx = <double>[]; final gy = <double>[]; final gz = <double>[];

    for (final s in window) {
      ax.add(s['ax'] ?? 0.0);
      ay.add(s['ay'] ?? 0.0);
      az.add(s['az'] ?? 0.0);
      gx.add(s['gx'] ?? 0.0);
      gy.add(s['gy'] ?? 0.0);
      gz.add(s['gz'] ?? 0.0);
    }

    final feats = <String, double>{};
    feats.addAll(_stats('ACCELEROMETER_X', ax));
    feats.addAll(_stats('ACCELEROMETER_Y', ay));
    feats.addAll(_stats('ACCELEROMETER_Z', az));
    feats.addAll(_stats('GYROSCOPE_X', gx));
    feats.addAll(_stats('GYROSCOPE_Y', gy));
    feats.addAll(_stats('GYROSCOPE_Z', gz));

    feats['corr__ACCELEROMETER_X__ACCELEROMETER_Y'] = _corr(ax, ay);
    feats['corr__ACCELEROMETER_Y__ACCELEROMETER_Z'] = _corr(ay, az);
    feats['corr__ACCELEROMETER_X__ACCELEROMETER_Z'] = _corr(ax, az);
    feats['corr__GYROSCOPE_X__GYROSCOPE_Y'] = _corr(gx, gy);
    feats['corr__GYROSCOPE_Y__GYROSCOPE_Z'] = _corr(gy, gz);
    feats['corr__GYROSCOPE_X__GYROSCOPE_Z'] = _corr(gx, gz);

    return feats;
  }
}
