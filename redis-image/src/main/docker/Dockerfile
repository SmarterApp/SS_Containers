FROM redis:3.2-alpine

RUN apk add --update \
    bash \
    curl \
    python \
  && rm -rf /var/cache/apk/*

COPY redis-master.conf /redis-master/redis.conf
COPY redis-slave.conf /redis-slave/redis.conf
COPY run.sh /run.sh
COPY live_check.sh /live_check.sh
COPY sentinel_check.sh /sentinel_check.sh

CMD [ "/run.sh" ]
ENTRYPOINT [ "sh", "-c" ]