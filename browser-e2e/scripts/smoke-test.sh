#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Valida uma imagem browser-e2e ja construida.

Dependencias:
  Bash 4.4+ e Docker 24+ (ou Podman 4+) com acesso ao daemon.

Uso:
  smoke-test.sh --image REFERENCIA
  smoke-test.sh --help

Parametros:
  --image REFERENCIA  Imagem local que sera validada.
  -h, --help          Exibe esta ajuda e encerra.

Exemplo:
  bash browser-e2e/scripts/smoke-test.sh --image local/browser-e2e:test

Documentacao: browser-e2e/README.md
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
playwright --version | grep -q "1\.65\.0"
google-chrome --version
microsoft-edge --version
"$BRAVE_EXECUTABLE" --version
"$FIREFOX_EXECUTABLE" --version
"$FIREFOX_ESR_EXECUTABLE" --version | grep -q esr
geckodriver --version | grep -q "0\.37\.1"
node -e "require(\"selenium-webdriver\")"' || fail "navegadores ou ferramentas ausentes"

"$ENGINE" run --rm --ipc=host "$image_ref" node -e '
const { chromium } = require("playwright");
(async () => {
  for (const channel of ["chrome", "msedge"]) {
    const browser = await chromium.launch({ channel });
    const page = await browser.newPage();
    await page.setContent("<title>ok</title>");
    if ((await page.title()) !== "ok") throw new Error(channel);
    await browser.close();
  }
  const brave = await chromium.launch({ executablePath: process.env.BRAVE_EXECUTABLE });
  await brave.close();
})().catch((e) => { console.error(e); process.exit(1); });' || fail "Playwright nao abriu Chrome, Edge ou Brave"

echo "Smoke test concluido: $image_ref"
