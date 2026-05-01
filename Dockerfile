FROM alpine:latest

RUN apk add --no-cache logrotate docker-cli tzdata

ENV LOGROTATE_STATE_FILE=/var/lib/logrotate/logrotate.status \
  LOGROTATE_INCLUDE_DIR=/etc/logrotate.d \
  LOGROTATE_MAIN_CONFIG=/etc/logrotate.conf \
  LOGROTATE_OPTIONS="-v"

RUN mkdir -p /logs /var/lib/logrotate \
  && rm -f /etc/logrotate.d/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY config/logrotate.conf /etc/logrotate.conf.default

RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/logs", "/var/lib/logrotate", "/etc/logrotate.d"]

CMD ["/usr/local/bin/entrypoint.sh"]
