# Flutter App - Hybrid IDS (Smartphone Sensors)

This Flutter app reads **accelerometer + gyroscope** in real-time, builds a rolling window, extracts features, and calls the FastAPI backend to classify **Normal vs Intrusion**.

## Requirements
- Flutter SDK (3.4+ recommended)
- Android Studio / VS Code
- A running backend on your PC (see `../backend_fastapi/README.md`)

## Setup
```bash
cd flutter_app
flutter pub get
flutter run
```

## Configure API URL
In `lib/main.dart`, set:
- Emulator: `http://10.0.2.2:8000` (Android emulator)
- Real phone: `http://YOUR_PC_IP:8000`

Example:
```dart
final api = IDSApi(baseUrl: 'http://192.168.0.10:8000');
```

## How it works
- Sampling loop: ~20Hz (50ms timer)
- Window size: from `model_meta.json`
- Features: mean/std/min/max/median/energy for each axis + correlation pairs
- Sends features to `/predict`
- Shows alert when `prediction == 1`
