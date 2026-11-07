<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# browser-e2e

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fbrowser--e2e-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-1.65.0--v1-2E7D32)
![Base](https://img.shields.io/badge/base-lzocateli%2Fnode%3A24.22.1--bookworm--v1-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Executa testes E2E em Node.js 24 LTS: Playwright com Chrome, Edge e Brave estáveis, e Selenium com geckodriver para Firefox ESR e estável. A imagem cobre também testes de extensões de navegador; no Firefox, isso é feito pelo comando `webExtension.install` do WebDriver BiDi. Em relação a `lzocateli/playwright-e2e` (Python), usa Node.js e inclui navegadores de marca e o Firefox ESR.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/browser-e2e:1.65.0-v1` |
| Imagem base | `lzocateli/node:24.22.1-bookworm-v1` (fixada por digest) |
| Plataformas | `linux/amd64` |
| Usuário padrão | `node` (`1000:1000`) |
| Entry point | nenhum; `CMD ["playwright", "--version"]` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/browser-e2e` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/browser-e2e` |

## Conteúdo e finalidade

### Incluído

- Node.js 24.22.1 (LTS), da imagem base.
- `playwright` e `@playwright/test` 1.65.0, instalados globalmente.
- Chromium do Playwright (Chrome for Testing), além de Google Chrome e Microsoft Edge estáveis, instalados pelo Playwright.
- Brave estável, do repositório oficial da Brave.
- Firefox estável e Firefox ESR, do repositório oficial da Mozilla.
- `selenium-webdriver` 4.52.0 e geckodriver 0.37.1 (com SHA-256 verificado).
- `xvfb`, para extensões que exigem modo com interface.

### Não incluído

- Os testes do projeto consumidor, que são montados em `/workspace`.
- WebKit do Playwright.
- `linux/arm64`, porque o Edge não é distribuído para essa arquitetura no Linux.

## Início rápido

```bash
docker pull lzocateli/browser-e2e:1.65.0-v1
docker run --rm lzocateli/browser-e2e:1.65.0-v1
```

Rodar a suíte Playwright do projeto:

```bash
docker run --rm --ipc=host \
  --volume "$PWD:/workspace" \
  lzocateli/browser-e2e:1.65.0-v1 \
  npx playwright test
```

## Docker Compose

```yaml
services:
  e2e:
    image: lzocateli/browser-e2e:1.65.0-v1
    ipc: host
    working_dir: /workspace
    volumes:
      - ./frontend:/workspace
    command: ["npx", "playwright", "test"]
```

## Testes de extensão

Resultado verificado pelo smoke test (`scripts/probe-extensions.js`), que carrega uma extensão MV3 por `--load-extension`:

| Navegador | Carrega extensão por linha de comando | Uso recomendado |
| --- | --- | --- |
| Chromium (Chrome for Testing) | Sim | Extensões em Playwright (`channel: "chromium"`) |
| Microsoft Edge | Sim | Extensões em Playwright (`channel: "msedge"`) |
| Brave | Sim | Extensões em Playwright (`executablePath: process.env.BRAVE_EXECUTABLE`) |
| Google Chrome estável | Não, desde a versão 137 | Páginas comuns; extensões só por outra via, como o WebDriver BiDi |
| Firefox estável e ESR | Não se aplica | Extensões via Selenium e `webExtension.install` do WebDriver BiDi |

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `PLAYWRIGHT_BROWSERS_PATH` | Não | Não | `/ms-playwright` | Navegadores e dependências do Playwright. |
| `BRAVE_EXECUTABLE` | Não | Não | `/usr/bin/brave-browser` | Use em `executablePath` do Playwright. |
| `FIREFOX_EXECUTABLE` | Não | Não | `/usr/bin/firefox` | Firefox estável para o Selenium. |
| `FIREFOX_ESR_EXECUTABLE` | Não | Não | `/usr/bin/firefox-esr` | Firefox ESR para o Selenium. |
| `NODE_PATH` | Não | Não | `/usr/local/lib/node_modules` | Permite `require` dos pacotes globais. |

### Portas

A imagem não expõe portas.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Testes, relatórios e traces | Não |

### Secrets

Credenciais de teste devem vir de variáveis injetadas pelo CI ou do arquivo de secrets externo do projeto. Não versione nem copie esses valores para a imagem.

## Inicialização e ciclo de vida

Cada execução roda a suíte indicada e termina com o código de saída dela. Não há health check.

## Segurança

- Executa como usuário não root `node`.
- Use `--ipc=host` (ou `--shm-size=1g`) para o Chrome; não use `--privileged`.
- Os repositórios de pacotes de Brave e Mozilla são verificados pelas chaves oficiais.
- Os navegadores estáveis são instalados no momento do build; a versão exata fica registrada na saída do smoke test, e cada rebuild gera uma nova tag `vN`.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/browser-e2e:1.65.0-v1 \
  browser-e2e
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `1.65.0-v1` | Imutável | Playwright 1.65.0, Selenium 4.52.0, geckodriver 0.37.1 | CI e E2E |

Uma troca de versão do Playwright gera nova tag. Um rebuild com navegadores mais novos sobre o mesmo Playwright incrementa `vN`.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes;
- análise do Dockerfile com BuildKit;
- `bash browser-e2e/scripts/smoke-test.sh --image <ref>`, que verifica o usuário não root, a presença das versões, o Firefox ESR e o geckodriver, a abertura de Chrome, Edge e Brave pelo Playwright e o carregamento de uma extensão MV3 no Chromium, no Edge e no Brave;
- inspeção de vulnerabilidades com `tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath browser-e2e`;
- SBOM e proveniência na publicação.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `browser-e2e`;
- `image_name`: `browser-e2e`;
- `image_tag`: `1.65.0-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

Reconstrua periodicamente para receber correções de segurança dos navegadores, gerando nova tag `vN`.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| Chrome fecha ao iniciar | `/dev/shm` pequeno | Logs do Playwright | Use `--ipc=host` ou `--shm-size=1g` |
| Extensão não carrega no Chrome | O Chrome de marca ignora `--load-extension` desde a versão 137 | `node scripts/probe-extensions.js --extension <dir>` | Use `channel: "chromium"` (Chrome for Testing) ou Edge |
| Selenium não encontra o Firefox | Binário não informado | `echo $FIREFOX_ESR_EXECUTABLE` | Defina `binary` nas opções do Firefox |

## Limitações conhecidas

- Somente `linux/amd64`.
- O suporte do Playwright ao Brave não é oficial; a imagem só fornece o binário.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem base `lzocateli/node` | 24.22.1-bookworm-v1 | MIT e licenças upstream | `https://github.com/lzocateli/containers/tree/main/node` |
| Playwright | 1.65.0 | Apache-2.0 | `https://github.com/microsoft/playwright` |
| Chromium (Chrome for Testing) | da versão do Playwright | BSD-3-Clause e licenças do Chromium | `https://googlechromelabs.github.io/chrome-for-testing/` |
| selenium-webdriver | 4.52.0 | Apache-2.0 | `https://github.com/SeleniumHQ/selenium` |
| geckodriver | 0.37.1 | MPL-2.0 | `https://github.com/mozilla/geckodriver` |
| Firefox e Firefox ESR | estável e ESR no build | MPL-2.0 | `https://www.mozilla.org/firefox/` |
| Google Chrome | estável no build | Termos de serviço do Google Chrome | `https://www.google.com/chrome/` |
| Microsoft Edge | estável no build | Termos de licença do Microsoft Edge | `https://www.microsoft.com/edge` |
| Brave | estável no build | MPL-2.0 | `https://brave.com` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Chrome e Edge são distribuídos sob termos próprios dos fabricantes. Use esta imagem apenas para testes, sem redistribuir os navegadores separadamente. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `1.65.0-v1`: primeira versão.
