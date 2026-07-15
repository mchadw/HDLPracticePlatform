# Slim sandbox image for compiling/simulating Verilog with Icarus.
# Used for offline/manual runs now; judge wiring comes later.
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends iverilog \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
