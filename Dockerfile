FROM tcely/powerdns-recursor:latest
LABEL maintainer=peter@peterspain.co.uk

ARG CONFIG=/etc/pdns-recursor/recursor.conf

RUN apk add --no-cache bash bind-tools
RUN sed -i -e "s/disable-syslog=/c\disable-syslog=yes/" "${CONFIG}" && \
    sed -i -e "s/log-timestamp=/c\log-timestamp=no/" "${CONFIG}" && \
    sed -i -e "s/local-address=/c\local-address=0.0.0.0/" "${CONFIG}" && \
    sed -i -e "s/setuid=/c\setuid=pdns-recursor/" "${CONFIG}" && \
    sed -i -e "s/setgid=/c\setgid=pdns-recursor/" "${CONFIG}"

COPY docker-entrypoint.sh /usr/local/bin
COPY healthcheck.sh /usr/local/bin

RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
