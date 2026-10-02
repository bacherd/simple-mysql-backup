FROM alpine:3.24
LABEL maintainer="Dominik Bacher"

RUN apk add --no-cache mariadb-client mariadb-connector-c tini tzdata

ENV TZ=UTC

COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
