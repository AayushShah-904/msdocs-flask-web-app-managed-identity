# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Install system dependencies needed for psycopg2 compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Create a non-privileged system user and group
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app -s /sbin/nologin appuser

# Set work directory
WORKDIR /app

# Set correct ownership for work directory
RUN chown appuser:appgroup /app

# Switch to the non-privileged user
USER appuser

# Copy requirements and install dependencies
COPY --chown=appuser:appgroup requirements.txt /app/
RUN pip install --no-cache-dir --user -r requirements.txt

# Add user pip bin directory to PATH
ENV PATH="/app/.local/bin:${PATH}"

# Copy the rest of the project files
COPY --chown=appuser:appgroup . /app/

# Expose port 8000
EXPOSE 8000

# Run migrations and start Gunicorn
CMD ["sh", "-c", "flask db upgrade && gunicorn --bind=0.0.0.0:8000 --timeout 120 app:app"]
