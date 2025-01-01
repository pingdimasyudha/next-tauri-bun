# 1.1.42-alpine
FROM oven/bun@sha256:fa47bde9713df05cac86c013abbf1965a348f9de80a73c025a72510ef802d4d3 AS builder
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

COPY --chown=nonroot:nonroot ./package.json ./bun.lockb ./
RUN bun i --production \
          --frozen-lockfile

COPY --chown=nonroot:nonroot . .
RUN bun build:web

# 1.1.42-distroless
FROM oven/bun@sha256:bf85edcaa2195ff152d1fe897b95c90b067e42ce10ad67677af94e576cab6781
USER nonroot:nonroot
WORKDIR /home/nonroot

COPY --from=builder \
     --chown=nonroot:nonroot \
     --chmod=755 /tini /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=builder \
     --chown=nonroot:nonroot /home/nonroot/build/standalone .
CMD ["bun", "./server.js"]