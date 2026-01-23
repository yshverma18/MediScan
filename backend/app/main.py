# app/main.py

# Explanation:
#
# Defines API endpoints:
# - /health: Check backend + model status.
# - /users/register: Create or get a simple user by email.
# - /predict: Upload image, run inference, store prediction.
# - /predictions/history: Get recent predictions (optionally by user).
#
from fastapi import FastAPI, Depends, HTTPException
from http.client import HTTPException
from typing import Optional

from fastapi import FastAPI, UploadFile, File, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .model_service import run_inference, INPUT_SIZE
from .database import Base, engine
from . import models
from .deps import get_db


# Create DB tables on startup (SQLite)
Base.metadata.create_all(bind=engine)

app = FastAPI(title="MediScan Demo Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok", "input_shape": [INPUT_SIZE[0], INPUT_SIZE[1], 3]}


@app.post("/users/register")
async def register_user(
    email: str,
    name: Optional[str] = None,
    password: Optional[str] = None,
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        user = models.User(email=email, name=name, password=password)
        db.add(user)
        db.commit()
        db.refresh(user)
    return {"id": user.id, "email": user.email, "name": user.name}

@app.post("/users/login")
async def login_user(
    email: str,
    password: str,
    db: Session = Depends(get_db),
):
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None or user.password != password:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return {"id": user.id, "email": user.email, "name": user.name}




@app.post("/predict")
async def predict(
    image: UploadFile = File(...),
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """
    Run model inference on uploaded image.
    Optionally attach prediction to a user_id.
    """
    label, prob, topk = await run_inference(image)

    # Save prediction record in DB
    pred = models.Prediction(
        user_id=user_id,
        image_name=image.filename,
        label=label,
        confidence=prob,
    )
    db.add(pred)
    db.commit()
    db.refresh(pred)

    return {
        "label": label,
        "probability": prob,
        "topk": topk,
        "prediction_id": pred.id,
    }


@app.get("/predictions/history")
async def prediction_history(
    user_id: Optional[int] = None,
    db: Session = Depends(get_db),
):
    """
    Return recent prediction history.
    - If user_id is provided, filter by user.
    - Otherwise return latest predictions overall (up to 50).
    """
    query = db.query(models.Prediction).order_by(models.Prediction.created_at.desc())
    if user_id is not None:
        query = query.filter(models.Prediction.user_id == user_id)

    rows = query.limit(50).all()
    return [
        {
            "id": p.id,
            "user_id": p.user_id,
            "image_name": p.image_name,
            "label": p.label,
            "confidence": p.confidence,
            "created_at": p.created_at.isoformat(),
        }
        for p in rows
    ]
