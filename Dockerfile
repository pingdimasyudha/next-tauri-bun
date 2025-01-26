# 1.2.0-alpine
FROM oven/bun@sha256:f857945c180d6f3dca180961ff2753c1f0b372ccb7b04af4257c2243b7e8201e AS builder
RUN addgroup -g 10001 \
             -S nonroot \
    && adduser -G nonroot \
               -h /home/nonroot \
               -S \
               -u 10000 nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot

ARG TINI_CHECKSUM=c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee \
    TINI_VERSION=v0.19.0
ADD --checksum=sha256:${TINI_CHECKSUM} \
    --chown=nonroot:nonroot https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini

COPY --chown=nonroot:nonroot ./package.json ./bun.lock ./
RUN bun i --frozen-lockfile

COPY --chown=nonroot:nonroot . .
RUN bun build:web

# 1.1.45-distroless
FROM oven/bun@sha256:994252d8978f7fb4f12fb123c30d4405a46addc679f2cf1836d47f7350ce21b2
USER nonroot:nonroot
WORKDIR /home/nonroot

COPY --from=builder \
     --chown=nonroot:nonroot \
     --chmod=755 /tini /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=builder \
     --chown=nonroot:nonroot /home/nonroot/build/standalone .
CMD ["bun", "./server.js"]