# syntax=docker/dockerfile:1

# Imagem oficial do .NET 10 SDK com os pré-requisitos de Native AOT (clang, lld e zlib).
# mcr.microsoft.com/dotnet/sdk:10.0.403-noble-aot
FROM mcr.microsoft.com/dotnet/sdk@sha256:e5b1f5150f66079aa409eec64042a13de475530864825bf85d575188d3c8d3f9 AS runtime

ARG IMAGE_VERSION="10.0.403-noble-aot-v1"

LABEL org.opencontainers.image.title="lzocateli/dotnet-sdk-aot" \
	org.opencontainers.image.description=".NET 10 SDK (LTS) com toolchain Native AOT para publicar binários nativos Linux em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/dotnet-sdk-aot" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/dotnet-sdk-aot" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

RUN install --directory --owner="${APP_UID}" --group="${APP_UID}" /workspace

WORKDIR /workspace

USER ${APP_UID}:${APP_UID}

CMD ["dotnet", "--info"]
