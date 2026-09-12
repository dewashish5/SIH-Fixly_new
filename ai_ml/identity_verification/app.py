from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import cv2
import numpy as np
import requests
from io import BytesIO
import traceback

app = FastAPI(title="Fixly Identity Verification", version="2.0")

class VerificationRequest(BaseModel):
    documentUrl: str
    selfieUrl: str

class VerificationResponse(BaseModel):
    success: bool
    documentFaceDetected: bool
    selfieFaceDetected: bool
    faceMatch: dict
    liveness: dict
    imageQuality: float
    error: str = None

def download_image(url: str) -> np.ndarray:
    """Download image from URL and convert to OpenCV format"""
    response = requests.get(url, timeout=15)
    response.raise_for_status()
    img_array = np.frombuffer(response.content, np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Could not decode image from URL: {url}")
    return img

def assess_image_quality(img: np.ndarray) -> float:
    """Assess image quality based on sharpness (Laplacian variance)"""
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    # Normalize: 0-1 scale, values > 500 are very sharp
    return round(min(1.0, laplacian_var / 500.0), 3)

@app.post("/verify", response_model=VerificationResponse)
async def verify_identity(req: VerificationRequest):
    try:
        # Import DeepFace here to allow graceful failure if not installed
        from deepface import DeepFace
        
        # Download images
        doc_img = download_image(req.documentUrl)
        selfie_img = download_image(req.selfieUrl)
        
        # Assess image quality
        quality_score = assess_image_quality(selfie_img)
        
        # Detect faces in document
        doc_face_detected = False
        try:
            doc_faces = DeepFace.extract_faces(
                doc_img, 
                detector_backend='opencv',  # Fast fallback, use 'retinaface' if available
                enforce_detection=False
            )
            doc_face_detected = len(doc_faces) > 0 and doc_faces[0].get('confidence', 0) > 0.5
        except Exception:
            doc_face_detected = False
        
        # Detect faces in selfie
        selfie_face_detected = False
        try:
            selfie_faces = DeepFace.extract_faces(
                selfie_img,
                detector_backend='opencv',
                enforce_detection=False
            )
            selfie_face_detected = len(selfie_faces) > 0 and selfie_faces[0].get('confidence', 0) > 0.5
        except Exception:
            selfie_face_detected = False
        
        # Face matching
        face_match_score = 0.0
        face_matched = False
        try:
            result = DeepFace.verify(
                doc_img, selfie_img,
                model_name='VGG-Face',
                detector_backend='opencv',
                enforce_detection=False
            )
            # Convert distance to 0-100 score (lower distance = higher match)
            # VGG-Face cosine distance threshold is typically 0.40
            distance = result.get('distance', 1.0)
            threshold = result.get('threshold', 0.40)
            # Score: 100 at distance=0, 0 at distance=1
            face_match_score = round(max(0, min(100, (1 - distance) * 100)), 2)
            face_matched = result.get('verified', False)
        except Exception as e:
            face_match_score = 0.0
            face_matched = False
        
        # Liveness check (basic: face detected in selfie + reasonable quality)
        liveness_passed = selfie_face_detected and quality_score > 0.15
        liveness_score = round(min(1.0, quality_score * 1.2) if selfie_face_detected else 0.0, 3)
        
        return VerificationResponse(
            success=True,
            documentFaceDetected=doc_face_detected,
            selfieFaceDetected=selfie_face_detected,
            faceMatch={
                "matched": face_matched,
                "score": face_match_score
            },
            liveness={
                "passed": liveness_passed,
                "score": liveness_score
            },
            imageQuality=quality_score
        )
        
    except requests.RequestException as e:
        raise HTTPException(status_code=400, detail=f"Failed to download image: {str(e)}")
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@app.get("/health")
async def health():
    return {"status": "ok", "service": "identity-verification", "version": "2.0"}

@app.get("/")
async def root():
    return {"status": "ok", "service": "identity-verification", "version": "2.0"}


if __name__ == "__main__":
    import os
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8004")))
