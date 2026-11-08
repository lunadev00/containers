#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem Rust ja construida.

Dependencias:
  Bash 4.4+ e Docker 24+ (ou Podman 4+) com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help

Parametros:
  --image REFERENCIA  Imagem local que sera validada.
  -h, --help          Exibe esta ajuda e encerra.

Exemplo:
  bash rust/scripts/smoke-test.sh --image local/rust:test

Documentacao: rust/README.md
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

"$ENGINE" run --rm "$image_ref" bash -c '
set -e
rustc --version | grep -q "^rustc 1\.99\.1 "
rustup target list --installed | grep -qx wasm32-unknown-unknown
wasm-bindgen --version | grep -q "0\.2\.130"
cargo afl --version >/dev/null
pkg-config --exists libsodium
pkg-config --exists openssl' || fail "toolchain incompleto"

"$ENGINE" run --rm --tmpfs /tmp:exec "$image_ref" bash -c '
set -e
cd /tmp
cargo new --lib --quiet smoke
cd smoke
printf "\n[lib]\ncrate-type = [\"cdylib\"]\n" >> Cargo.toml
cargo build --quiet --target wasm32-unknown-unknown
test -f target/wasm32-unknown-unknown/debug/smoke.wasm' || fail "build wasm32 falhou"

echo "Smoke test concluido: $image_ref"
