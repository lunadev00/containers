# syntax=docker/dockerfile:1

ARG RUST_IMAGE="rust:1.99.1-slim-bookworm@sha256:f2c004e3d2d8b547e8cf7ffbc29205385f4e71d23e53e4e383065db5e9f822cd"

FROM ${RUST_IMAGE} AS build

ARG WASM_BINDGEN_VERSION=0.2.130

RUN apt-get update \
	&& apt-get install --yes --no-install-recommends pkg-config libssl-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,target=/usr/local/cargo/registry \
	cargo install --locked --root /opt/cargo-tools "wasm-bindgen-cli@${WASM_BINDGEN_VERSION}"

FROM ${RUST_IMAGE} AS runtime

ARG IMAGE_VERSION="1.99.1-bookworm-v1"
ARG WASM_BINDGEN_VERSION=0.2.130
ARG CARGO_AFL_VERSION=0.18.2

LABEL org.opencontainers.image.title="lzocateli/rust" \
	org.opencontainers.image.description="Rust stable com alvo wasm32-unknown-unknown, wasm-bindgen-cli, cargo-afl, libsodium e OpenSSL para builds e testes em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/rust" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/rust" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

# libsodium-dev e libssl-dev servem a testes diferenciais; make e clang compilam o AFL++ do cargo-afl.
RUN apt-get update \
	&& apt-get install --yes --no-install-recommends \
	clang \
	libsodium-dev \
	libssl-dev \
	make \
	pkg-config \
	&& rm -rf /var/lib/apt/lists/* \
	&& rustup target add wasm32-unknown-unknown \
	&& rustup component add clippy rustfmt \
	&& groupadd --gid 10001 rust \
	&& useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin rust \
	&& install --directory --owner=10001 --group=10001 /workspace

COPY --from=build /opt/cargo-tools/bin/ /usr/local/bin/

# Registro e caches do cargo ficam no home do usuário não root; o toolchain continua somente leitura.
ENV CARGO_HOME=/home/rust/.cargo \
	PATH=/home/rust/.cargo/bin:/usr/local/cargo/bin:${PATH}

USER 10001:10001

# A instalação do cargo-afl compila o runtime do AFL++ a partir dos fontes no registro do cargo;
# por isso ocorre no estágio final, no CARGO_HOME do usuário, no canal stable e sem o recurso
# plugins (que exige nightly).
RUN cargo install --locked "cargo-afl@${CARGO_AFL_VERSION}" \
	&& cargo afl --version

WORKDIR /workspace

CMD ["cargo", "--version"]
