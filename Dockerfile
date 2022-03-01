FROM eclipse-mosquitto:2 AS builder

RUN apk --no-cache add --virtual build-deps \
    make=4.3-r0 cmake=3.20.3-r0 libpng-dev=1.6.37-r1 zlib-dev=1.2.11-r3 \
    boost-dev=1.76.0-r0 git=2.32.0-r0 g++=10.3.1_git20210424-r2

# hadolint ignore=DL3003
RUN git clone --recursive https://github.com/edward3h/bedrock-viz.git && \
    cd bedrock-viz && \
    git switch alpine && \
    git apply -p0 patches/leveldb-1.22.patch && \
    git apply -p0 patches/pugixml-disable-install.patch && \
    mkdir build && cd build && \
    cmake .. && make install

FROM alpine:3.15
RUN apk --no-cache add jq=1.6-r1 rsync=3.2.3-r5
COPY --from=builder /usr/local/share/bedrock-viz /usr/local/share/bedrock-viz
COPY --from=builder /usr/local/bin/bedrock-viz /usr/local/bin/
COPY --from=builder /usr/bin/mosquitto* /usr/bin/
COPY --from=builder /usr/lib/* /usr/lib/

WORKDIR /app
COPY app/* /app/

VOLUME [ "/data", "/backups" ]

CMD [ "./run.sh" ]
