FROM alpine:3.9
MAINTAINER Dominik Bacher

RUN apk add --update mariadb-client shadow && rm -rf /var/cache/apk/* 

COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
