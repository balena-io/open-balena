FROM haproxy:2.9-alpine

VOLUME [ "/certs" ]

RUN apk add --update inotify-tools

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY start-haproxy.sh /start-haproxy

CMD /start-haproxy
