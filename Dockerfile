# ==========================================
# Strapi 5 - Production
# ==========================================

FROM node:22-bookworm-slim AS build

# Dependências necessárias para o Sharp/Strapi
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        python3 \
        libvips-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia apenas os arquivos de dependências primeiro
# para aproveitar o cache do Docker
COPY package.json package-lock.json ./

RUN npm ci

# Copia o restante do projeto
COPY . .

# Compila o painel administrativo do Strapi
RUN npm run build


# ==========================================
# Production image
# ==========================================

FROM node:22-bookworm-slim AS production

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=1337

# libvips é necessário em runtime para o Sharp
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libvips \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia arquivos de dependências
COPY package.json package-lock.json ./

# Instala somente dependências de produção
RUN npm ci --omit=dev

# Copia o código da aplicação
COPY --from=build /app/config ./config
COPY --from=build /app/database ./database
COPY --from=build /app/public ./public
COPY --from=build /app/src ./src
COPY --from=build /app/types ./types
COPY --from=build /app/dist ./dist

# Cria diretório de uploads caso não exista
RUN mkdir -p /app/public/uploads

# Executa como usuário não-root
USER node

EXPOSE 1337

# Inicia o Strapi em modo produção
CMD ["npm", "run", "start"]
