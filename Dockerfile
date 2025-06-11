# Use the official Ubuntu image as the base image
FROM python:3.13-slim-bookworm AS base

# Set up a working directory
WORKDIR /app

# build stage
FROM base AS builder

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# install PDM
RUN pip install -U pdm
# disable update check
ENV PDM_CHECK_UPDATE=false
# copy files
COPY pyproject.toml pdm.lock README.md /app/

# install dependencies and project into the local packages directory
RUN pdm install --check --prod --no-editable

# run stage
FROM base

# Set environment variables to avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages for Xvfb and pyvirtualdisplay
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    chromium \
    gnupg \
    ca-certificates \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    libnss3 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    x11-apps \
    fonts-liberation \
    libappindicator3-1 \
    libu2f-udev \
    libvulkan1 \
    libdrm2 \
    xdg-utils \
    xvfb \
    tini \
    && rm -rf /var/lib/apt/lists/*

# retrieve packages from build stage
COPY --from=builder /app/.venv/ /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy application files
COPY src src

# Expose the port for the FastAPI server
EXPOSE 8000

# Setup tini as entrypoint so zombie processes are cleared
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default command
CMD ["python", "src/server.py"]
