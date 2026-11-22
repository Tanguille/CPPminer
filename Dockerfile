# Cluster image: CUDA backend for the RTX 2070 (sm_75) only.
# Context is a checkout of an upstream release tag (see the workflow), not this repo.
FROM docker.io/nvidia/cuda:13.5.0-devel-ubuntu24.04@sha256:d3fa71793540a2b76ab227ee00016e754da2758b7a51b49bc8a72543af5a8bc2 AS build

RUN apt-get update \
 && apt-get install -y --no-install-recommends cmake g++ git curl unzip ca-certificates libgomp1 \
 && rm -rf /var/lib/apt/lists/*

# cp-proof-ffi is built by cmake via cargo; pin the toolchain.
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain 1.100.0

WORKDIR /src
COPY . .
RUN ./build.sh --backend cpu,cuda --cuda-arch 75

FROM docker.io/nvidia/cuda:13.5.0-runtime-ubuntu24.04@sha256:ba4d4e8475ced890fb26f9661daf8dae7cce9827613682eb8b8379c5ecd94eba

# The miner ignores SIGTERM; tini makes pod stop immediate.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libgomp1 tini \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /src/build/cmake/cppminer /usr/local/bin/cppminer
# MIT requires the copyright notice to ship with copies.
COPY --from=build /src/LICENSE /usr/share/doc/cppminer/LICENSE

ARG SOURCE_SHA
ARG UPSTREAM_TAG
LABEL org.opencontainers.image.source="https://github.com/Tanguille/CPPminer" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.revision="${SOURCE_SHA}" \
      org.opencontainers.image.version="${UPSTREAM_TAG}"

USER 1000:1000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/cppminer"]
