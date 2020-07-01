# Build librespot
FROM rust:latest AS librespot_builder
RUN git clone https://github.com/librespot-org/librespot /librespot \
  && cd /librespot && cargo build --release --no-default-features


# Build snapserver container
FROM ubuntu:20.04
RUN  apt-get update \
  && apt-get install -y wget ca-certificates curl jq findutils \
  && rm -rf /var/lib/apt/lists/*

# Download the latest release of snapcast
RUN curl -s  https://api.github.com/repos/badaix/snapcast/releases/latest | \
    jq -r '.assets[].browser_download_url | select(.|contains("server") and (.|contains("amd64.deb")))' | \
    head -n 1 | \
    xargs wget -O /tmp/snapcast.deb \
    && apt-get update \
    && apt install -f -y /tmp/snapcast.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/snapcast.deb


COPY --from=librespot_builder /librespot/target/release/librespot /usr/bin/

RUN mkdir -p /tmp/snapcast
COPY snapserver.conf /etc/snapserver.conf
EXPOSE 1704 1705 1780
ENTRYPOINT ["/bin/bash","-c","source /etc/default/snapserver && snapserver $SNAPSERVER_OPTS"]
