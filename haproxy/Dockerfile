FROM haproxy:1.8-alpine

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY entry.sh /open-balena-entry

EXPOSE 80 443

CMD /open-balena-entry
