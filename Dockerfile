FROM ubuntu:25.04

# Basic tools + sudo (needed for passwordless apt as sstt)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git make unzip bubblewrap bzip2 \
	binaryen cmake g++ libcurl4-gnutls-dev libexpat1-dev libgmp-dev libssl-dev ninja-build pkg-config \
	curl npm \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# Create user sstt with a home dir and bash shell
RUN useradd -m -s /bin/bash sstt

# Make sure ~/.local/bin exists and is on PATH for sstt
RUN mkdir -p /home/sstt/.local/bin && \
    chown -R sstt:sstt /home/sstt

ENV PATH="/home/sstt/.local/bin:${PATH}"

# Copy the local Makefile into the image, into sstt's home

COPY --chown=sstt:sstt Makefile /home/sstt/Makefile

USER sstt
WORKDIR /home/sstt
RUN curl -L -o .local/bin/opam https://github.com/ocaml/opam/releases/download/2.5.2/opam-2.5.2-x86_64-linux  && \
    chmod +x .local/bin/opam && \
    opam init --bare --disable-sandboxing

RUN make .popl-24-installed && \
    make sstt/.stamp && \
    make MLsem/.stamp && \
    cd sstt && \
    make web-deps js wasm && \
    cp -r web ..

EXPOSE 8000

CMD ["python3", "-m", "http.server", "-d", "web"]
