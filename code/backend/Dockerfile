FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Add this to your backend Dockerfile
RUN mkdir -p /backend/staticfiles
RUN chmod -R 777 /backend/staticfiles

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gettext \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /backend

# Install dependencies
COPY requirements.txt /backend/
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy project
COPY . /backend/

# Create a non-root user and switch to it
RUN useradd -m appuser && chown -R appuser:appuser /backend
USER appuser

# Run Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi:application"]