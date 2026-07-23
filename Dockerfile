FROM ubuntu:25.04
LABEL org.opencontainers.image.authors="Kim Nguyen <kn@lmf.cnrs.fr>"
LABEL org.opencontainers.image.title="Implementing Set-Theoretic Types Artifact"
LABEL org.opencontainers.image.description="Docker image allowing to reproduce the results of the paper \"Implementing Set-Theoretic Types\""
LABEL org.opencontainers.image.source="https://github.com/Tchou/stt-impl-artifact"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="1.0"

# Basic tools + sudo (needed for passwordless apt as sstt)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    binaryen bzip2 ca-certificates \
    cmake curl dc g++ git libcurl4-gnutls-dev \
    libexpat1-dev libgmp-dev libssl-dev \
    make ninja-build npm pkg-config python3 unzip \
    && rm -rf /var/lib/apt/lists/*

# Create user sstt with a home dir and bash shell
RUN useradd -m -s /bin/bash sstt

# Make sure ~/.local/bin exists and is on PATH for sstt
RUN mkdir -p /home/sstt/.local/bin && \
    chown -R sstt:sstt /home/sstt
RUN echo '/usr/bin/' | bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)"

# Copy the local Makefile into the image, into sstt's home

COPY --chown=sstt:sstt Makefile /home/sstt/Makefile

USER sstt
WORKDIR /home/sstt
RUN opam init --bare --disable-sandboxing

RUN make .deps-installed
RUN make Prototype-v1.2.3/.stamp \
         cduce/.stamp \
         sstt/.stamp \
         MLsem/.stamp
RUN make .cduce-installed
RUN cd sstt && \
    make web-deps js wasm && \
    cp -r web ..

EXPOSE 8000

CMD ["python3", "-m", "http.server", "-d", "web"]
