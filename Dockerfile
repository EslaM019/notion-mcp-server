# Use Node.js LTS as the base image
FROM node:20-slim AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install all dependencies, including devDependencies required for the build
# (typescript and esbuild are devDependencies but needed by `npm run build`)
RUN npm ci --ignore-scripts

# Copy source code
COPY . .

# Build the package (TypeScript compilation + CLI bundling via esbuild)
RUN npm run build

# Prune devDependencies so only production dependencies are kept
RUN npm prune --omit=dev

# Minimal image for runtime
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy built CLI binary, production node_modules, the OpenAPI spec, and package.json
COPY --from=builder /app/bin ./bin
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/scripts/notion-openapi.json ./scripts/notion-openapi.json
COPY --from=builder /app/package.json ./package.json

# Set default environment variables
ENV OPENAPI_MCP_HEADERS="{}"

# Set entrypoint - bin/cli.mjs is the bundled server built by esbuild
ENTRYPOINT ["node", "bin/cli.mjs"]
