# Complete Project: AI‑Driven Hybrid Intrusion Detection (Smartphone Sensor Data)

This project contains:
1. **FastAPI backend** (Python) that loads your trained scikit‑learn models (`.joblib`) and exposes a REST API.
2. **Flutter mobile app** that reads smartphone sensors, extracts features, calls the backend, and shows intrusion alerts.

## Folder structure
- `backend_fastapi/`  → Python API (runs on laptop/PC or cloud)
- `flutter_app/`      → Flutter app (Android/iOS)

## Quick start (local testing)
### 1) Run backend
```bash
cd backend_fastapi
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

### 2) Run Flutter
```bash
cd flutter_app
flutter pub get
flutter run
```

**Important for Android:**
- Emulator uses: `http://10.0.2.2:8000`
- Real phone uses your PC IP (same Wi‑Fi): `http://192.168.x.x:8000`

## Model metadata
- Window size (rows): 50
- Step (rows): 25
- Feature count: 120
- Anomaly threshold T: 0.5102382694880999

## Notes
- This implementation keeps your dissertation model exactly (Isolation Forest + Logistic Regression).
- For full offline inference, we would need model conversion (ONNX/TFLite) and to replace IsolationForest on-device.
