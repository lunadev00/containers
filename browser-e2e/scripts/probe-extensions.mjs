#!/usr/bin/env node
// Verifica quais navegadores da imagem carregam uma extensão MV3 por linha de comando.
//
// Uso: node probe-extensions.mjs --extension DIR [--require chromium[,outro]]
//      node probe-extensions.mjs --help
// Saída: uma linha "navegador: carregou" ou "navegador: não carregou" por navegador;
// código 1 quando um navegador listado em --require não carregar a extensão.
// Documentação: browser-e2e/README.md

import fs from "node:fs";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";

// O Playwright está instalado globalmente; o carregador CommonJS respeita NODE_PATH.
const require = createRequire(import.meta.url);
const { chromium } = require("playwright");

function usage() {
  console.log(`Verifica o carregamento de uma extensão MV3 em Chromium, Chrome, Edge e Brave.

Dependências: Node.js 24 e Playwright da imagem browser-e2e.

Uso:
  node probe-extensions.mjs --extension DIR [--require chromium[,chrome,msedge,brave]]
  node probe-extensions.mjs --help

Exemplo:
  node probe-extensions.mjs --extension /fixtures/mv3-extension --require chromium

Documentação: browser-e2e/README.md`);
}

function parseArgs(argv) {
  const args = { extension: "", require: [] };
  let index = 0;
  while (index < argv.length) {
    const value = argv[index];
    const next = argv[index + 1];
    if (value === "--help" || value === "-h") {
      usage();
      process.exit(0);
    } else if (value === "--extension" && next) {
      args.extension = next;
      index += 1;
    } else if (value === "--require" && next) {
      args.require = next.split(",").filter(Boolean);
      index += 1;
    } else {
      console.error(`erro: argumento inválido: ${value}; consulte --help`);
      process.exit(2);
    }
    index += 1;
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
  try {
    const context = await chromium.launchPersistentContext(profile, {
      ...browser.options,
      headless: true,
      args: [`--disable-extensions-except=${extensionDir}`, `--load-extension=${extensionDir}`],
    });
    try {
      const worker = context.serviceWorkers()[0]
        ?? await context.waitForEvent("serviceworker", { timeout: 10000 }).catch(() => undefined);
      return worker?.url().startsWith("chrome-extension://") ?? false;
    } finally {
      await context.close();
    }
  } catch (error) {
    console.error(`${browser.name}: erro ao iniciar (${error.message.split("\n")[0]})`);
    return false;
  } finally {
    fs.rmSync(profile, { recursive: true, force: true });
  }
}

const args = parseArgs(process.argv.slice(2));
const extensionDir = path.resolve(args.extension);
const results = await Promise.all(browsers.map(async (browser) => ({
  name: browser.name,
  loaded: await probe(browser, extensionDir),
})));

let failed = false;
for (const { name, loaded } of results) {
  console.log(`${name}: ${loaded ? "carregou" : "não carregou"}`);
  if (!loaded && args.require.includes(name)) failed = true;
}
process.exit(failed ? 1 : 0);
