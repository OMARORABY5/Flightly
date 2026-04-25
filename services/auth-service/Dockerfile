# Auth Service Dockerfile
# Multi-stage: development and production ready

FROM node:20-alpine AS base
WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Expose service port
EXPOSE 3001

# Health check — Docker will restart container if unhealthy
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3001/health || exit 1

# Start the service
CMD ["node", "server.js"]
