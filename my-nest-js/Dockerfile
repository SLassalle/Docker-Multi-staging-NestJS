FROM node:latest AS builder

WORKDIR /app

COPY ./package.json .

RUN npm install

COPY . .

RUN npm run build


FROM oven/bun:alpine AS server

WORKDIR /app

COPY --from=builder /app/dist ./dist

COPY ./package.json .

RUN bun install --production

CMD ["bun", "dist/main"]