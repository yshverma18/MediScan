

import io
import os
from typing import List, Tuple

import numpy as np
import cv2
from PIL import Image
from fastapi import UploadFile
import tensorflow as tf  # full TensorFlow for TFLite

# -----------------------------------------------------------------------------
# PATHS & CONSTANTS
# -----------------------------------------------------------------------------

BASE_DIR = os.path.dirname(os.path.dirname(__file__))  # e.g., backend/
ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")
MODEL_PATH = os.path.join(ARTIFACTS_DIR, "model_export", "model.tflite")
LABELS_TXT = os.path.join(BASE_DIR, "labels.txt")

INPUT_SIZE = (224, 224)

# -----------------------------------------------------------------------------
# SAFETY GUARD THRESHOLDS
# -----------------------------------------------------------------------------
# Extreme non‑skin: almost no skin pixels at all
SKIN_RATIO_MIN = 0.03      # 3%

# "Low skin" region: likely non‑skin or object
SKIN_RATIO_LOW = 0.20        # 20%

# Confidence thresholds
CONFIDENCE_UNCERTAIN = 0.70  # below this → "uncertain"
CONFIDENCE_STRONG = 0.90     # need this when skin_ratio is low

# -----------------------------------------------------------------------------
# LOAD LABELS
# -----------------------------------------------------------------------------
with open(LABELS_TXT, "r") as f:
    LABELS: List[str] = [line.strip() for line in f if line.strip()]

# -----------------------------------------------------------------------------
# LOAD TFLITE MODEL ONCE
# -----------------------------------------------------------------------------
_interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
_interpreter.allocate_tensors()
_input_details = _interpreter.get_input_details()
_output_details = _interpreter.get_output_details()

# -----------------------------------------------------------------------------
# SKIN RATIO ESTIMATION
# -----------------------------------------------------------------------------
def _estimate_skin_ratio(bgr_img: np.ndarray) -> float:
    """
    Rough skin detector in YCrCb color space.
    Returns fraction of pixels that look like skin in [0, 1].
    """
    ycrcb = cv2.cvtColor(bgr_img, cv2.COLOR_BGR2YCrCb)

    skin_mask = cv2.inRange(
        ycrcb,
        (30, 140, 90),    # Y, Cr, Cb lower bound
        (235, 165, 130)   # Y, Cr, Cb upper bound
    )

    skin_pixels = np.count_nonzero(skin_mask)
    total_pixels = skin_mask.size
    if total_pixels == 0:
        return 0.0

    return skin_pixels / float(total_pixels)

# -----------------------------------------------------------------------------
# CENTER CROP (ZOOM TOWARD LESION REGION)
# -----------------------------------------------------------------------------
def _center_crop(arr_rgb: np.ndarray, crop_factor: float = 0.8) -> np.ndarray:
    """
    Deterministic center crop to lightly zoom in.

    crop_factor = 0.8 → keep 80% of width/height around the center.
    This assumes the lesion is roughly centered (as in HAM10000/ISIC).
    """
    h, w, _ = arr_rgb.shape
    new_h = max(int(h * crop_factor), 1)
    new_w = max(int(w * crop_factor), 1)

    top = (h - new_h) // 2
    left = (w - new_w) // 2
    bottom = top + new_h
    right = left + new_w

    return arr_rgb[top:bottom, left:right, :]

# -----------------------------------------------------------------------------
# IMAGE PREPROCESSING (val/test TRANSFORMS + CENTER CROP)
# -----------------------------------------------------------------------------
def _preprocess_image(img: Image.Image) -> Tuple[np.ndarray, float]:
    """
    Preprocess PIL image for the model and also return skin_ratio for guard checks.

    Mirrors PyTorch val/test transforms, with a mild center crop to zoom:
      - compute skin_ratio on full image
      - center crop (zoom) on RGB
      - Resize to 224x224
      - Scale to [0,1]
      - Normalize with ImageNet mean/std
    """
    rgb = img.convert("RGB")
    arr_rgb_full = np.array(rgb)  # (H, W, 3), uint8

    # Skin ratio on original image
    arr_bgr_full = cv2.cvtColor(arr_rgb_full, cv2.COLOR_RGB2BGR)
    skin_ratio = _estimate_skin_ratio(arr_bgr_full)

    # Mild center crop to zoom toward the lesion area
    arr_rgb = _center_crop(arr_rgb_full, crop_factor=0.8)

    # Resize to model input size (224x224)
    arr_rgb = cv2.resize(arr_rgb, INPUT_SIZE, interpolation=cv2.INTER_LINEAR)

    # Scale to [0,1]
    arr = arr_rgb.astype("float32") / 255.0

    # Normalize with ImageNet mean/std
    mean = np.array([0.485, 0.456, 0.406], dtype="float32")
    std = np.array([0.229, 0.224, 0.225], dtype="float32")
    arr = (arr - mean) / std

    # Add batch dimension: [1, H, W, C]
    arr = np.expand_dims(arr, axis=0)

    return arr, skin_ratio

# -----------------------------------------------------------------------------
# MAIN INFERENCE FUNCTION
# -----------------------------------------------------------------------------
async def run_inference(file: UploadFile, top_k: int = 3) -> Tuple[str, float, List[dict]]:
    """
    Run TFLite inference on an uploaded image file.

    Returns:
        top_label: str
            - "invalid"   → obvious non‑skin / object
            - "uncertain" → skin present but low model confidence
            - <disease>   → confident prediction from model
        top_prob: float
        topk: List[dict]
    """
    data = await file.read()
    img = Image.open(io.BytesIO(data))

    x, skin_ratio = _preprocess_image(img)

    # ------------------------------------------------------------------
    # GUARD 1: extreme non‑skin (almost no skin pixels)
    # ------------------------------------------------------------------
    if skin_ratio < SKIN_RATIO_MIN:
        return "invalid", 0.0, []

    # ------------------------------------------------------------------
    # MODEL INFERENCE
    # ------------------------------------------------------------------
    _interpreter.set_tensor(_input_details[0]["index"], x)
    _interpreter.invoke()

    output = _interpreter.get_tensor(_output_details[0]["index"])[0]  # [num_classes]

    # Softmax → probabilities
    exp = np.exp(output - np.max(output))
    probs = exp / np.sum(exp)

    # Top‑k
    top_indices = probs.argsort()[::-1][:top_k]
    topk = [
        {"label": LABELS[i], "p": float(probs[i])}
        for i in top_indices
    ]

    top_label = LABELS[top_indices[0]]
    top_prob = float(probs[top_indices[0]])

    # ------------------------------------------------------------------
    # GUARD 2: low‑confidence → "uncertain"
    # ------------------------------------------------------------------
    if top_prob < 0.70:
        return "uncertain", top_prob, topk

    # ------------------------------------------------------------------
    # GUARD 3: focus on skin amount
    # If skin content is low AND confidence is not extremely high,
    # treat it as "invalid" (likely non‑skin object like a flower).
    # ------------------------------------------------------------------
    if skin_ratio < 0.30:
        return "invalid", top_prob, topk

    # ------------------------------------------------------------------
    # NORMAL CASE: confident prediction for a skin image
    # ------------------------------------------------------------------
    return top_label, top_prob, topk
