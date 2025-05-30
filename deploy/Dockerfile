# Build stage
FROM node:20-slim AS builder
WORKDIR /usr/src/app
COPY package.json yarn.lock tsconfig.json ./
COPY src ./src
RUN yarn install --frozen-lockfile
RUN yarn build

# Production stage
FROM node:20-slim
WORKDIR /app
COPY --from=builder /usr/src/app/dist ./dist
COPY package.json . 
# No node_modules copied!
ENV NODE_ENV=production
EXPOSE 3001
ENTRYPOINT ["node", "dist/app.js"]
