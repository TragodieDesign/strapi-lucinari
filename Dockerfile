
FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

# Permite que o Node utilize mais memória durante
# a compilação do painel administrativo.
ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm run build


FROM node:22-bookworm-slim AS production

WORKDIR /app
ENV NODE_OPTIONS="--max-old-space-size=3072"
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=1337

COPY package.json package-lock.json ./

RUN npm ci --omit=dev

COPY --from=build /app/config ./config
COPY --from=build /app/database ./database
COPY --from=build /app/public ./public
COPY --from=build /app/src ./src
COPY --from=build /app/types ./types
COPY --from=build /app/dist ./dist

RUN mkdir -p /app/public/uploads

USER node

EXPOSE 1337

CMD ["npm", "run", "start"]
