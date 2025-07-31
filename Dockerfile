# Multi-stage build for production
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine AS production

# Install bash for shell scripts
RUN apk add --no-cache bash curl

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy backend scripts
COPY --from=builder /app/src/backend /opt/nginxui/backend

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Make scripts executable
RUN chmod +x /opt/nginxui/backend/*.sh

# Create necessary directories
RUN mkdir -p /var/log/nginxui /var/lib/nginxui /etc/nginxui

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]