FROM ubuntu:22.04 AS builder

# hadolint ignore=DL3015
RUN apt-get update && apt-get install -y git\
    cmake libpng++-dev zlib1g-dev\
    libboost-program-options-dev g++

COPY patches/* /patches/

# hadolint ignore=DL3003
RUN git clone --recursive https://github.com/bedrock-viz/bedrock-viz.git && \
    cd bedrock-viz && \
    git apply -p0 patches/leveldb-1.22.patch && \
    git apply -p0 patches/pugixml-disable-install.patch && \
    git apply -p1 /patches/193.patch && \
    mkdir build && cd build && \
    cmake .. && make install

FROM ubuntu:22.04
RUN apt-get update && apt-get install --no-install-recommends -y mosquitto-clients \
    rsync openssh-client jq unzip \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/share/bedrock-viz /usr/local/share/bedrock-viz
COPY --from=builder /usr/local/bin/bedrock-viz /usr/local/bin/
COPY --from=builder /usr/lib/* /usr/lib/

WORKDIR /app
COPY app/* /app/

VOLUME [ "/data", "/backups" ]

CMD [ "./run.sh" ]
