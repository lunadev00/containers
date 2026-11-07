#!/usr/bin/env node
// Verifica quais navegadores da imagem carregam uma extensão MV3 por linha de comando.
//
// Uso: node probe-extensions.js --extension DIR [--require chromium[,outro]]
//      node probe-extensions.js --help
// Saída: uma linha "navegador: carregou" ou "navegador: não carregou" por navegador;
// código 1 quando um navegador listado em --require não carregar a extensão.
// Documentação: browser-e2e/README.md

"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { chromium } = require("playwright");

function usage() {
  console.log(`Verifica o carregamento de uma extensão MV3 em Chromium, Chrome, Edge e Brave.

Dependências: Node.js 24 e Playwright da imagem browser-e2e.

Uso:
  node probe-extensions.js --extension DIR [--require chromium[,chrome,msedge,brave]]
  node probe-extensions.js --help

Exemplo:
  node probe-extensions.js --extension /fixtures/mv3-extension --require chromium

Documentação: browser-e2e/README.md`);
}

function parseArgs(argv) {
  const args = { extension: "", require: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const value = argv[i];
    if (value === "--help" || value === "-h") {
      usage();
      process.exit(0);
    } else if (value === "--extension" && argv[i + 1]) {
      args.extension = argv[i += 1];
    } else if (value === "--require" && argv[i + 1]) {
      args.require = argv[i += 1].split(",").filter(Boolean);
    } else {
      console.error(`erro: argumento inválido: ${value}; consulte --help`);
      process.exit(2);
    }
  }
  if (!args.extension) {
    console.error("erro: --extension é obrigatório; consulte --help");
    process.exit(2);
  }
  return args;
}

const browsers = [
  { name: "chromium", options: { channel: "chromium" } },
  { name: "chrome", options: { channel: "chrome" } },
  { name: "msedge", options: { channel: "msedge" } },
  { name: "brave", options: { executablePath: process.env.BRAVE_EXECUTABLE } },
];

async function probe(browser, extensionDir) {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), `probe-${browser.name}-`));
  const context = await chromium.launchPersistentContext(profile, {
    ...browser.options,
    headless: true,
    args: [`--disable-extensions-except=${extensionDir}`, `--load-extension=${extensionDir}`],
  });
  try {
    const worker = context.serviceWorkers()[0]
      ?? await context.waitForEvent("serviceworker", { timeout: 10000 }).catch(() => undefined);
    return Boolean(worker && worker.url().startsWith("chrome-extension://"));
  } finally {
    await context.close();
    fs.rmSync(profile, { recursive: true, force: true });
  }
}

(async () => {
  const args = parseArgs(process.argv.slice(2));
  let failed = false;
  for (const browser of browsers) {
    let loaded = false;
    try {
      loaded = await probe(browser, path.resolve(args.extension));
    } catch (error) {
      console.error(`${browser.name}: erro ao iniciar (${error.message.split("\n")[0]})`);
    }
    console.log(`${browser.name}: ${loaded ? "carregou" : "não carregou"}`);
    if (!loaded && args.require.includes(browser.name)) failed = true;
  }
  process.exit(failed ? 1 : 0);
})();
