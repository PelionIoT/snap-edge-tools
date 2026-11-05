# The connectivity scripts, with the tools they call, and ssh to reach the suite gateway.
FROM debian:12.8-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl netcat-openbsd iputils-ping \
        python3 sshpass openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY . /work/snap-edge-tools
WORKDIR /work/snap-edge-tools
