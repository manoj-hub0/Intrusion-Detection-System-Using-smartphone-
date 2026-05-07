from fastapi import FastAPI
from pydantic import BaseModel
import joblib, json
import numpy as np

app = FastAPI(title="Hybrid IDS API", version="1.0")

# Load models (scikit-learn pipelines)
anomaly = joblib.load("anomaly_iforest.joblib")
clf = joblib.load("classifier_logreg.joblib")
meta = json.load(open("model_meta.json", "r", encoding="utf-8"))

FEATURES = meta["feature_columns"]
T = float(meta["anomaly_threshold_T"])

class PredictReq(BaseModel):
    features: dict  # { "feature_name": value, ... }

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict")
def predict(req: PredictReq):
    # Vector in training feature order
    x = np.array([req.features.get(f, 0.0) for f in FEATURES], dtype=float).reshape(1, -1)

    # Stage A score (respect pipeline steps if present)
    imputer = anomaly.named_steps.get("imputer", None)
    scaler = anomaly.named_steps.get("scaler", None)
    iforest = anomaly.named_steps["iforest"]

    xt = x
    if imputer is not None:
        xt = imputer.transform(xt)
    if scaler is not None:
        xt = scaler.transform(xt)

    score = float(-iforest.score_samples(xt)[0])
    gated = bool(score >= T)

    # Stage B probability (classifier pipeline handles its own preprocessing)
    p = float(clf.predict_proba(x)[0, 1])
    if not gated:
        p = min(p, 0.10)

    pred = int(p >= 0.5)

    return {
        "anomaly_score": score,
        "gated": gated,
        "intrusion_probability": p,
        "prediction": pred
    }
