FROM python:3.10-slim

# Install system dependencies required for OpenCV and image processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Upgrade pip and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Pre-download VGG-Face model weights during build so container is ready instantly
RUN python3 -c "from deepface import DeepFace; DeepFace.build_model('VGG-Face')" || true

# Copy application source code
COPY app.py .

EXPOSE 8004

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8004/health || exit 1

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8004"]
