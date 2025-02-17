FROM node:latest AS base

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./


FROM base AS development

CMD ["npm", "run", "start:dev", "--", "--host", "0.0.0.0"]


FROM base AS build

RUN npm run build


FROM oven/bun:alpine AS production

COPY --from=build /app/dist ./dist

COPY ./package.json .

RUN bun install --production

CMD ["bun", "dist/main"]