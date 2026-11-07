# syntax=docker/dockerfile:1

# Prometheus 3.13 é a linha LTS vigente; a imagem expõe somente o promtool.
FROM prom/prometheus:v3.13.5@sha256:aafa9d694e6a883c02db516d9f6e5b84e14195f49a2a6456a4cca815edda72b9 AS runtime

ARG IMAGE_VERSION="3.13.5-v1"

LABEL org.opencontainers.image.title="lzocateli/promtool" \
	org.opencontainers.image.description="promtool do Prometheus 3.13 LTS para validar e testar regras de alerta e gravação em contêineres." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/promtool" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/promtool" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

WORKDIR /work

USER 65534:65534

ENTRYPOINT ["/bin/promtool"]
CMD ["--version"]
