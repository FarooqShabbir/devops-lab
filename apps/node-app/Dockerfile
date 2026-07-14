# --- build stage ---
FROM node:20-slim AS builder
WORKDIR /build
COPY apps/node-app/package.json .
RUN npm install --omit=dev --package-lock=false

# --- runtime stage ---
FROM node:20-slim
WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY apps/node-app/server.js .
COPY apps/node-app/package.json .
ENV NODE_ENV=production APP_ENV=production PORT=3000
USER node
EXPOSE 3000
HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]
