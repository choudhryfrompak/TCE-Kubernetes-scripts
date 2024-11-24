# Build stage
FROM node:20.18-alpine as build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./
COPY frontend/ frontend/
COPY turbo.json ./

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies
RUN pnpm install

# Copy project files
COPY . .

# Build project
RUN pnpm build:web

# Production stage
FROM nginx:alpine

# Copy built files to nginx
COPY --from=build /app/frontend/apps/web/dist /usr/share/nginx/html

# Copy nginx configuration (optional but recommended)
COPY frontend/apps/web/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]