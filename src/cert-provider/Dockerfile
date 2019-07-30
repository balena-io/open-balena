FROM alpine

EXPOSE 80
WORKDIR /usr/src/app
VOLUME [ "/usr/src/app/certs" ]

RUN apk add --update bash curl git openssl ncurses socat

RUN git clone https://github.com/Neilpang/acme.sh.git && \
    cd acme.sh && \
    git checkout 08357e3cb0d80c84bdaf3e42ce0e439665387f57 . && \
    ./acme.sh --install  \
    --cert-home /usr/src/app/certs

COPY entry.sh /entry.sh
COPY cert-provider.sh ./cert-provider.sh
COPY fake-le-bundle.pem ./

ENTRYPOINT [ "/entry.sh" ]
CMD [ "/usr/src/app/cert-provider.sh" ]