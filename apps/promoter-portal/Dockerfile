# Builds the web app and serves it with Caddy (see infra/Caddyfile).
# Build context is the repository root: docker-compose.prod.yml sets it.
FROM node:22-alpine AS build
WORKDIR /app
COPY apps/promoter-portal/package.json apps/promoter-portal/package-lock.json ./
RUN npm ci
COPY apps/promoter-portal/ ./
RUN npm run build

FROM caddy:2.8-alpine
COPY infra/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/dist /srv/web
