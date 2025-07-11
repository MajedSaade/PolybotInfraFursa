# Use minimal Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (for building and running your Python packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    libssl-dev \
    libgl1 \
    libglib2.0-0 \
    libjpeg-dev \
    zlib1g-dev \
    libsqlite3-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install torch first (copies torch-specific dependencies)
COPY torch-requirements.txt torch-requirements.txt
RUN pip install --no-cache-dir -r torch-requirements.txt

# Install other Python requirements
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy entire application source code into container
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV YOLO_CONFIG_DIR=/app/.yolo-config

# Run the FastAPI app
CMD ["python", "app.py"]
