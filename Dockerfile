FROM node:22-bookworm AS builder

WORKDIR /app

RUN corepack enable

COPY . .

RUN pnpm install --frozen-lockfile
RUN pnpm run build

FROM node:22-bookworm-slim AS runtime

WORKDIR /app

RUN corepack enable

COPY --from=builder /app /app

ENV NODE_ENV=production
ENV PORT=3080

EXPOSE 3080

CMD ["pnpm", "dsh", "web", "--no-open"]
