from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Identity Verification API", version="1.0")

@app.get("/")
def health_check():
    return {"status": "Identity Verification API running"}

class VerificationRequest(BaseModel):
    documentUrl: str
    selfieUrl: str

@app.post("/verify")
def verify_identity(req: VerificationRequest):
    if not req.documentUrl or not req.selfieUrl:
        raise HTTPException(status_code=400, detail="Both documentUrl and selfieUrl are required.")
    
    # In a real implementation, we would download the images and use DeepFace.
    # For the SIH Demo, we return simulated measurements.
    
    if len(req.documentUrl) < 5 or len(req.selfieUrl) < 5:
        return {
            "success": True,
            "document": {
                "faceDetected": False,
                "qualityScore": 0.1
            },
            "selfie": {
                "faceDetected": False,
                "qualityScore": 0.1,
                "livenessPassed": False,
                "livenessScore": 0.1
            },
            "faceMatch": {
                "matched": False,
                "score": 10.0
            }
        }
        
    return {
        "success": True,
        "document": {
            "faceDetected": True,
            "qualityScore": 0.93
        },
        "selfie": {
            "faceDetected": True,
            "qualityScore": 0.95,
            "livenessPassed": True,
            "livenessScore": 0.91
        },
        "faceMatch": {
            "matched": True,
            "score": 92.3
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8004)
