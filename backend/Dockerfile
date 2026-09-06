# ==========================================================
# Production Multi-Stage Dockerfile for AWS ECR & ECS (Fargate)
# ==========================================================
FROM node:20-alpine AS base

# Install security updates & dumb-init for proper signal handling in ECS
RUN apk update && apk add --no-cache dumb-init curl

WORKDIR /usr/src/app

# Install dependencies with production focus
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy application source
COPY . .

# Set production environment variables
ENV NODE_ENV=production
ENV PORT=8000

# Expose HTTP & Socket.io port
EXPOSE 8000

# Health check for AWS ECS Target Group
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# Run with non-root node user for container security
USER node

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
