# Multi-stage production build for ReliefHub
FROM node:20-slim AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy application source code
COPY . .

# Build Vite client production assets to /app/dist
RUN npm run build

# Prune dev dependencies for a lean production runtime
RUN npm prune --production

# Final runtime image
FROM node:20-slim AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Copy node modules and built assets from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server
COPY --from=builder /app/server.ts ./
COPY --from=builder /app/tsconfig.json ./
COPY --from=builder /app/src/types ./src/types

# Create persistent storage directory for json db
RUN mkdir -p /app/data

# Expose standard container port
EXPOSE 3000

# Start Express server (serves API and static dist assets)
CMD ["npx", "tsx", "server.ts"]
