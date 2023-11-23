FROM ubuntu:impish-20220531 AS builder

# hadolint ignore=DL3015
RUN apt-get update && apt-get install -y git=1:2.32.0-1ubuntu1 \
    cmake=3.18.4-2ubuntu2 libpng++-dev=0.2.10-1 zlib1g-dev=1:1.2.11.dfsg-2ubuntu7 \
    libboost-program-options-dev=1.74.0.3ubuntu6 g++=4:11.2.0-1ubuntu1

# hadolint ignore=DL3003
RUN git clone --recursive https://github.com/bedrock-viz/bedrock-viz.git && \
    cd bedrock-viz && \
    git apply -p0 patches/leveldb-1.22.patch && \
    git apply -p0 patches/pugixml-disable-install.patch && \
    mkdir build && cd build && \
    cmake .. && make install

FROM ubuntu:impish-20220531
RUN apt-get update && apt-get install --no-install-recommends -y mosquitto-clients=2.0.11-1 \
    rsync=3.2.3-4ubuntu1 openssh-client=1:8.4p1-6ubuntu2.1 jq=1.6-2.1ubuntu2 unzip=6.0-26ubuntu1 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/share/bedrock-viz /usr/local/share/bedrock-viz
COPY --from=builder /usr/local/bin/bedrock-viz /usr/local/bin/
COPY --from=builder /usr/lib/* /usr/lib/

WORKDIR /app
COPY app/* /app/

VOLUME [ "/data", "/backups" ]

CMD [ "./run.sh" ]
