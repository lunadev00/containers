<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# dotnet-sdk-aot

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fdotnet--sdk--aot-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-10.0.403--noble--aot--v1-2E7D32)
![Base](https://img.shields.io/badge/base-dotnet%2Fsdk%3A10.0.403--noble--aot-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

.NET 10 SDK (LTS) com os pré-requisitos de Native AOT (clang, lld e zlib) para publicar binários nativos Linux em contêineres. Difere de `lzocateli/dotnet-sdk` por usar a variante oficial `-aot` da Microsoft e não trazer as ferramentas de diagnóstico de rede.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1` |
| Imagem base | `mcr.microsoft.com/dotnet/sdk:10.0.403-noble-aot` (fixada por digest) |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `1654:1654` (`app`, via `APP_UID`) |
| Entry point | nenhum; `CMD ["dotnet", "--info"]` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/dotnet-sdk-aot` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/dotnet-sdk-aot` |

## Conteúdo e finalidade

### Incluído

- .NET SDK 10.0.403 (LTS).
- Toolchain Native AOT da variante oficial `noble-aot`.

### Não incluído

- Toolchains para Windows ou macOS: binários `win-*` e `osx-*` exigem runners desses sistemas.
- Workloads (MAUI, Android, iOS) e Native AOT para Android.

## Início rápido

```bash
docker pull lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1
docker run --rm lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1
```

Publicar um projeto em Native AOT para `linux-x64`:

```bash
docker run --rm \
  --volume "$PWD:/workspace" \
  lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1 \
  dotnet publish ./src/App/App.csproj --configuration Release --runtime linux-x64 -p:PublishAot=true --output ./out
```

## Docker Compose

```yaml
services:
  aot-build:
    image: lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1
    working_dir: /workspace
    volumes:
      - ./:/workspace
    command: ["dotnet", "publish", "--configuration", "Release", "--runtime", "linux-x64", "-p:PublishAot=true"]
```

## Configuração

### Variáveis de ambiente

A imagem herda as variáveis da base oficial (`DOTNET_*`, `APP_UID`) e não adiciona outras.

### Portas

A imagem não expõe portas.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Código-fonte e saída do publish | Não (fonte no Git) |

O usuário `1654` precisa de escrita no diretório montado.

### Secrets

Feeds NuGet privados devem usar `--mount=type=secret` do BuildKit ou variáveis injetadas pelo CI. Nunca use `ARG` ou `ENV`.

## Inicialização e ciclo de vida

Cada execução roda um comando `dotnet` e termina com o código de saída dele. Não há health check.

## Segurança

- Executa como usuário não root `app` (`1654`).
- A base é a imagem oficial da Microsoft, fixada por digest.
- Contém compiladores por finalidade; use somente em build e CI, nunca como runtime.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1 \
  dotnet-sdk-aot
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/dotnet-sdk-aot:10.0.403-noble-aot-v1 \
  dotnet-sdk-aot
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `10.0.403-noble-aot-v1` | Imutável | .NET 10 SDK 10.0.403, Ubuntu 24.04 LTS | CI e builds AOT |

Cada nova feature band ou patch do SDK gera uma nova tag.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes;
- análise do Dockerfile com BuildKit;
- `bash dotnet-sdk-aot/scripts/smoke-test.sh --image <ref>`, que verifica o usuário não root, a versão do SDK e a publicação AOT de um console executado em seguida, selecionando `linux-x64` para AMD64 ou `linux-arm64` para ARM64 conforme a arquitetura da imagem;
- inspeção de vulnerabilidades com `tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath dotnet-sdk-aot`;
- SBOM e proveniência na publicação.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `dotnet-sdk-aot`;
- `image_name`: `dotnet-sdk-aot`;
- `image_tag`: `10.0.403-noble-aot-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

## Operação

Atualize junto com `lzocateli/dotnet-sdk` a cada patch do .NET 10, para manter o mesmo SDK nas duas imagens.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `Permission denied` ao gravar `obj/` | Diretório montado sem escrita para o UID 1654 | `ls -ln` no host | Ajuste o dono ou use `--user` compatível |
| Erro de linker para `win-x64`/`osx-*` | Native AOT não cruza sistemas operacionais | Conferir o `--runtime` | Publique no runner do sistema alvo |
| Smoke test AOT falha em ARM64 | Runtime incompatível ou erro de compilação | Consulte a saída de `dotnet publish` no job | Use o script atualizado, que seleciona o runtime pela arquitetura da imagem |

## Limitações conhecidas

- Compila Native AOT somente para alvos Linux (`linux-x64` e `linux-arm64`, cada um na própria plataforma da imagem).

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| .NET SDK | 10.0.403 | MIT | `https://github.com/dotnet/sdk` |
| Imagem base | `mcr.microsoft.com/dotnet/sdk:10.0.403-noble-aot` | MIT e licenças dos pacotes Ubuntu | `https://mcr.microsoft.com/product/dotnet/sdk` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `10.0.403-noble-aot-v1`: primeira versão.
