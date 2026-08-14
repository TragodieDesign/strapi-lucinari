FROM node:22-bookworm-slim AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

# Permite que o Node utilize mais memória durante a compilação
# do painel administrativo.
ENV NODE_OPTIONS="--max-old-space-size=4096"

RUN npm run build


FROM node:22-bookworm-slim AS production

WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=1337
ENV NODE_OPTIONS="--max-old-space-size=3072"

COPY --from=build /app/package.json ./package.json
COPY --from=build /app/package-lock.json ./package-lock.json
COPY --from=build /app/node_modules ./node_modules

# Copia os arquivos compilados pelo TypeScript
COPY --from=build /app/dist/config ./config
COPY --from=build /app/dist/src ./src

# Arquivos públicos do Strapi
COPY --from=build /app/public ./public

# O Strapi precisa criar/alterar migrations e uploads em runtime.
# Garantimos que o usuário node seja o proprietário desses arquivos.
RUN mkdir -p /app/database/migrations \
    /app/public/uploads \
    && chown -R node:node /app

USER node

EXPOSE 1337

CMD ["npm", "run", "start"]