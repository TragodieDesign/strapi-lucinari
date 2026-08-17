FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm run develop


FROM node:22-bookworm-slim AS production

WORKDIR /app

ENV NODE_ENV=development
ENV HOST=0.0.0.0
ENV PORT=1337
ENV NODE_OPTIONS="--max-old-space-size=3072"

COPY --from=build /app/package.json ./package.json
COPY --from=build /app/package-lock.json ./package-lock.json
COPY --from=build /app/node_modules ./node_modules

COPY --from=build /app/dist/config ./config
COPY --from=build /app/dist/src ./src
COPY --from=build /app/dist/build ./build

COPY --from=build /app/public ./public

COPY --from=build /app/database ./database

RUN mkdir -p /app/database/migrations \
    /app/public/uploads \
    && chown -R node:node /app

USER node

EXPOSE 1337

CMD ["npm", "run", "develop"]