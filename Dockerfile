# syntax=docker/dockerfile:1.7
ARG PYTHON_VERSION=3.12
ARG ALPINE_VERSION=alpine     # tracks latest Alpine release

FROM python:${PYTHON_VERSION}-${ALPINE_VERSION} AS builder
WORKDIR /opt/onix-attack-map

RUN apk add --no-cache --virtual .build-deps \
        build-base

COPY . .

RUN pip install --upgrade pip && \
    pip wheel -r requirements.txt -w /wheels

FROM python:${PYTHON_VERSION}-${ALPINE_VERSION}

RUN apk add --no-cache libcap tzdata && \
    addgroup -g 2000 map && \
    adduser  -S -H -s /sbin/nologin -u 2000 -G map map && \
    setcap 'cap_net_bind_service=+ep' "$(readlink -f "$(which python3)")"

ENV PYTHONUNBUFFERED=1 \
    TZ=UTC \
    APP_DIR=/opt/onix-attack-map
WORKDIR ${APP_DIR}

COPY --from=builder /wheels /wheels
COPY --from=builder ${APP_DIR} ${APP_DIR}

RUN pip install --no-cache --no-index --find-links=/wheels /wheels/* && \
    rm -rf /wheels && \
    chown -R map:map ${APP_DIR}

USER map:map

ENTRYPOINT ["sh", "-c"]
CMD ["python3 -u $APP_DIR/$MAP_COMMAND"]
