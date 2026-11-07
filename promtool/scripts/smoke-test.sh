#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem promtool ja construida.

Dependencias:
  Bash 4.4+ e Docker 24+ (ou Podman 4+) com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help

Parametros:
  --image REFERENCIA  Imagem local que sera validada.
  -h, --help          Exibe esta ajuda e encerra.

Exemplo:
  bash promtool/scripts/smoke-test.sh --image local/promtool:test

Documentacao: promtool/README.md
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

entrypoint="$("$ENGINE" image inspect --format '{{json .Config.Entrypoint}}' "$image_ref")"
[[ "$entrypoint" == '["/bin/promtool"]' ]] || fail "entrypoint inesperado: $entrypoint"

version_output="$("$ENGINE" run --rm --read-only "$image_ref" --version)"
[[ "$version_output" == *"version 3.13."* ]] || fail "versao inesperada: $version_output"

# Regra e teste minimos montados por stdin, sem arquivos no host.
"$ENGINE" run --rm --read-only --tmpfs /tmp --entrypoint /bin/sh "$image_ref" -c '
cat > /tmp/rules.yml <<EOR
groups:
  - name: smoke
    rules:
      - alert: SmokeAlerta
        expr: up == 0
        for: 1m
EOR
cat > /tmp/rules.test.yml <<EOT
rule_files: [rules.yml]
evaluation_interval: 1m
tests:
  - interval: 1m
    input_series:
      - series: up{job="smoke"}
        values: 0 0 0
    alert_rule_test:
      - eval_time: 2m
        alertname: SmokeAlerta
        exp_alerts:
          - exp_labels: {job: smoke}
EOT
cd /tmp && /bin/promtool check rules rules.yml && /bin/promtool test rules rules.test.yml' >/dev/null

echo "Smoke test concluido: $image_ref"
