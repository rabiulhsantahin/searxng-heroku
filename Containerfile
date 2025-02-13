FROM alpine:latest

EXPOSE 8080
VOLUME /etc/searxng
VOLUME /var/log/uwsgi

ENV INSTANCE_NAME=searx \
    SEARX_SETTINGS_PATH=/etc/searxng/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searxng/uwsgi.ini \
    CWD=/usr/local/searxng

WORKDIR $CWD

RUN adduser -u 977 -D -h "$CWD" -s /bin/sh searxng

RUN apk upgrade --no-cache \
 && apk add --no-cache --virtual build-dependencies \
        build-base \
        py3-setuptools \
        python3-dev \
        libffi-dev \
        libxslt-dev \
        libxml2-dev \
        openssl-dev \
        tar \
        git \
 && apk add --no-cache \
        ca-certificates \
        python3 \
        py3-pip \
        libxml2 \
        libxslt \
        openssl \
        tini \
        uwsgi \
        uwsgi-python3 \
        brotli \
 && git clone --depth 1 https://github.com/rabiulhsantahin/searxng-SearchEngine . \
 && chown -R searxng:searxng . \
 && pip3 install --upgrade pip \
 && pip3 install --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf /root/.cache

USER searxng

COPY settings.yml searxng/settings.yml

RUN python3 -m compileall -q searxng \
 && find searx/static -a \( -name "*.html" -o -name "*.css" -o -name "*.js" \
        -o -name "*.svg" -o -name "*.ttf" -o -name "*.eot" \) \
        -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+

RUN sed -e 's|DEFAULT_BIND_ADDRESS="0.0.0.0:8080"|DEFAULT_BIND_ADDRESS="0.0.0.0:$PORT"|g' \
        -e "s|su-exec searxng:searxng ||g" \
        -i dockerfiles/docker-entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/searxng/dockerfiles/docker-entrypoint.sh", "-f"]
