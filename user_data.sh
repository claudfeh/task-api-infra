#!/bin/bash
# Runs once, as root, on first boot of the EC2 instance.
# Installs Docker and launches the full task-api stack (db + app + proxy),
# with the app pulled as the image published by the Project 2 CI pipeline.
set -euo pipefail

# --- Docker engine ---
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# --- Docker Compose plugin ---
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# --- App stack (same shape as the local docker-compose.yml,
#     but the app comes from GHCR instead of a local build) ---
mkdir -p /opt/task-api

cat > /opt/task-api/docker-compose.yml <<'COMPOSE_EOF'
services:
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: tasks
      POSTGRES_USER: taskuser
      POSTGRES_PASSWORD: taskpass
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taskuser -d tasks"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ${image}
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: tasks
      DB_USER: taskuser
      DB_PASSWORD: taskpass
    networks:
      - backend
      - frontend

  proxy:
    image: nginx:1.27-alpine
    restart: unless-stopped
    depends_on:
      app:
        condition: service_healthy
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - frontend

networks:
  frontend:
  backend:

volumes:
  pgdata:
COMPOSE_EOF

cat > /opt/task-api/nginx.conf <<'NGINX_EOF'
upstream api {
    server app:5000;
}

server {
    listen 80;

    location /health {
        proxy_pass http://api/health;
    }

    location /api/ {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location = / {
        add_header Content-Type text/plain;
        return 200 'task-api is running. Try GET /api/tasks\n';
    }
}
NGINX_EOF

cd /opt/task-api
docker compose up -d
