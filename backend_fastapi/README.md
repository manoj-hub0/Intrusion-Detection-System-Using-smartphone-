# Backend (FastAPI) - Hybrid IDS

This backend loads the trained scikit-learn models (`.joblib`) and exposes a simple REST API for prediction.

## Files
- `app.py` - FastAPI app
- `anomaly_iforest.joblib` - anomaly detector pipeline
- `classifier_logreg.joblib` - classifier pipeline
- `model_meta.json` - feature order + thresholds
- `requirements.txt`

## Run locally
```bash
cd backend_fastapi
python -m venv .venv
# Windows
.venv\Scripts\activate
# macOS/Linux
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
```

## Test
Open:
- GET  http://127.0.0.1:8000/health
- POST http://127.0.0.1:8000/predict

Example request body:
```json
{
  "features": {
    "ACCELEROMETER_X__mean": 0.1
  }
}
```
