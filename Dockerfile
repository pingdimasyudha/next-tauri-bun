# 1.2.1-alpine
FROM oven/bun@sha256:fc66d85880a740870ff384fc344379715a8d5ffa7acf1e8ac07e90b46eea07e7 AS builder
RUN addgroup -g 10001 \
             -S nonroot \
    && adduser -G nonroot \
               -h /home/nonroot \
               -u 10000 \
               -S nonroot
USER nonroot:nonroot
WORKDIR /home/nonroot

COPY --chown=nonroot:nonroot \
     --chmod=0644 ./package.json \
                  ./bun.lock ./nayud-web/
RUN bun i --cwd ./nayud-web \
          --production \
          --frozen-lockfile

COPY --chown=nonroot:nonroot \
     --chmod=0755 . ./nayud-web
RUN bun run --cwd ./nayud-web build

# 1.27.3-alpine3.20
FROM nginxinc/nginx-unprivileged@sha256:9e7238f579a54582263a960d1b0094b4a3ecce641342eda3f8e2ff82b1703d2b
USER root:root
RUN addgroup -g 10001 \
             -S nonroot \
    && adduser -G nonroot \
               -h /home/nonroot \
               -u 10000 \
               -S nonroot
USER nonroot:nonroot

STOPSIGNAL SIGQUIT

EXPOSE 8080

ARG TINI_VERSION=v0.19.0
ADD --chown=nonroot:nonroot \
    --chmod=0755 https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=builder \
     --chown=nonroot:nonroot \
     --chmod=0644 /home/nonroot/nayud-web/build /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]