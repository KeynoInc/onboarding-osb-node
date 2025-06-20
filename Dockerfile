# Use the official Node.js image as the base image
FROM node:22-slim as builder

WORKDIR /usr/src/app
COPY package.json yarn.lock tsconfig.json ./
RUN yarn --frozen-lockfile
COPY src src
RUN npm run build
RUN yarn --frozen-lockfile --production

FROM node:22-slim

# Patch systemd/libudev vulnerabilities (CVE-2025-4598)
RUN apt-get update \
  && apt-get install -y --only-upgrade libudev1 libsystemd0 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
  
WORKDIR /app
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/src/assets/data/catalog.json ./dist/assets/data/catalog.json

ENV NODE_ENV=production

EXPOSE 3001

ENTRYPOINT [ "node", "dist/app.js" ]