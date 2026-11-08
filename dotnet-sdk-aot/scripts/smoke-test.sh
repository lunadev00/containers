#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem .NET SDK Native AOT ja construida.
Seleciona linux-x64 ou linux-arm64 conforme a arquitetura da imagem.

Dependencias:
  Bash 4.4+ e Docker 24+ (ou Podman 4+) com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help

Parametros:
  --image REFERENCIA  Imagem local que sera validada.
  -h, --help          Exibe esta ajuda e encerra.

Exemplo:
  bash dotnet-sdk-aot/scripts/smoke-test.sh --image local/dotnet-sdk-aot:test

Documentacao: dotnet-sdk-aot/README.md
EOF
}

fail() {
  printf 'erro: %s; consulte --help\n' "$1" >&2
  exit 1
}

image_ref=""
while (($# > 0)); do
  case "$1" in
    --image)
      (($# >= 2)) || fail "--image exige uma referencia"
      image_ref="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "argumento desconhecido: $1"
      ;;
  esac
done

[[ -n "$image_ref" ]] || fail "--image e obrigatorio"
if command -v docker.exe >/dev/null 2>&1; then
  ENGINE=docker.exe
elif command -v docker >/dev/null 2>&1; then
  ENGINE=docker
elif command -v podman >/dev/null 2>&1; then
  ENGINE=podman
else
  fail "Docker 24+ ou Podman 4+ nao foi encontrado"
fi

"$ENGINE" image inspect "$image_ref" >/dev/null 2>&1 || fail "imagem local nao encontrada: $image_ref"

user="$("$ENGINE" image inspect --format '{{.Config.User}}' "$image_ref")"
[[ -n "$user" && "$user" != "root" && "$user" != "0" && "$user" != 0:* ]] || fail "imagem executa como root: '$user'"

platform="$("$ENGINE" image inspect --format '{{.Os}}/{{.Architecture}}' "$image_ref")"
case "$platform" in
  linux/amd64) aot_runtime=linux-x64 ;;
  linux/arm64) aot_runtime=linux-arm64 ;;
  *) fail "plataforma nao suportada para Native AOT: $platform" ;;
esac

version_output="$("$ENGINE" run --rm "$image_ref" dotnet --version)"
[[ "$version_output" == 10.0.* ]] || fail "SDK inesperado: $version_output"

"$ENGINE" run --rm --tmpfs /tmp:exec --env "AOT_RUNTIME=$aot_runtime" "$image_ref" bash -c '
set -e
cd /tmp
dotnet new console --output aot --name aot
cd aot
dotnet publish --configuration Release --runtime "$AOT_RUNTIME" -p:PublishAot=true --output out
test "$(./out/aot)" = "Hello, World!"' || fail "publicacao Native AOT falhou para $aot_runtime"

echo "Smoke test concluido: $image_ref"
