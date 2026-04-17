FROM python:3.11-slim

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Set working directory
WORKDIR /app

# Copy the requirements/pyproject.toml file
COPY pyproject.toml /app/

# Install uv for fast dependency resolution (based on User preferences)
RUN pip install uv

# Install dependencies using uv
RUN uv pip install --system -r pyproject.toml

# Copy local code to the container image.
COPY . /app/

# Run the web service on container startup using uvicorn.
# Use $PORT environment variable, default to 8080.
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}
