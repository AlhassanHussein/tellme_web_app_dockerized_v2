FROM python:3.12-slim

# Create non-root user for security
RUN useradd -m -u 1000 appuser

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/ ./backend/

# Create data directory for SQLite database
RUN mkdir -p /app/data && chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# Production command (no --reload flag)
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
