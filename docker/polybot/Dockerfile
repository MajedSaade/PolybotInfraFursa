# Use minimal Python image (Alpine variant)
FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install system dependencies required by Python packages
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    jpeg-dev \
    zlib-dev \
    freetype-dev \
    libpng-dev \
    build-base

# Copy requirements and install Python dependencies
COPY polybot/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy the full source code
COPY polybot/ ./polybot

# (Optional) expose port if you have a web server or health endpoint
EXPOSE 8080

# Run the bot using Python module path
CMD ["python", "-m", "polybot.app"]
