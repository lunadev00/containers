<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# .NET 10 SDK

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fdotnet--sdk-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-10.0.403--noble--v1-2E7D32)
![Base](https://img.shields.io/badge/base-dotnet%2Fsdk%3A10.0--noble-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-BuildKit-success)

Imagem do .NET 10 SDK para compilação, testes e publicação de aplicações em pipelines de contêineres. Acrescenta ferramentas de diagnóstico de rede à imagem oficial; aplicações produzidas devem usar uma imagem de runtime, como `lzocateli/dotnet-aspnet`, no estágio final.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/dotnet-sdk:10.0.403-noble-v1` |
| Imagem base | Digest do manifest multi-arquitetura de `mcr.microsoft.com/dotnet/sdk:10.0-noble` |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `1654:1654` (`APP_UID` da imagem oficial) |
| Comando padrão | `dotnet --info` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/dotnet-sdk` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/dotnet-sdk` |

## Conteúdo e finalidade

### Incluído

- .NET SDK 10.0.403 e os runtimes 10.0.14 fornecidos pela imagem oficial Microsoft;
- `curl`, `iputils-ping`, `libxml2-dev`, `net-tools` e `telnet` instalados dos repositórios Ubuntu Noble;
- diretório `/workspace` gravável pelo usuário não root.

### Não incluído

- daemon ou cliente Docker;
- Node.js, PowerShell e ferramentas globais `dotnet`;
- credenciais de feeds NuGet, certificados privados ou código-fonte;
- aplicação ou runtime final de produção.

## Início rápido

```bash
docker pull lzocateli/dotnet-sdk:10.0.403-noble-v1
docker run --rm lzocateli/dotnet-sdk:10.0.403-noble-v1
```

Para compilar um projeto no diretório atual:

```bash
docker run --rm \
  --volume "$PWD:/workspace" \
  lzocateli/dotnet-sdk:10.0.403-noble-v1 \
  dotnet publish --configuration Release --output /workspace/out
```

O diretório montado deve permitir escrita pelo UID `1654`. Não monte o socket Docker nem execute como root sem necessidade explícita.

## Docker Compose

```yaml
services:
  build:
    image: lzocateli/dotnet-sdk:10.0.403-noble-v1
    user: "1654:1654"
    working_dir: /workspace
    volumes:
      - ./:/workspace
    command: ["dotnet", "publish", "--configuration", "Release", "--output", "/workspace/out"]
```

## Configuração

As variáveis `DOTNET_*`, `NUGET_*` e o comportamento do CLI seguem a imagem oficial. Não há variável própria obrigatória, porta exposta, volume declarado ou health check. Forneça tokens NuGet como secret do BuildKit ou do orquestrador, nunca por `ARG`, `ENV` no Dockerfile ou arquivo versionado.

## Inicialização e ciclo de vida

Sem entrypoint fixo, o primeiro argumento de `docker run` pode substituir `dotnet --info`. O processo executado torna-se o PID 1 e recebe diretamente os sinais do runtime. A imagem não executa bootstrap, migração ou serviço persistente.

## Segurança

- executa por padrão como UID/GID `1654:1654`;
- não requer capacidades Linux adicionais nem acesso privilegiado;
- pode usar filesystem somente leitura quando `/workspace` não precisar receber artefatos;
- contém compiladores e ferramentas de rede, portanto não deve ser o estágio final de uma aplicação;
- a base é fixada por digest e deve ser atualizada para receber correções upstream.

## Exemplo de build multi-stage

```dockerfile
# syntax=docker/dockerfile:1
FROM lzocateli/dotnet-sdk:10.0.403-noble-v1 AS build
WORKDIR /workspace
COPY --chown=1654:1654 . .
RUN --mount=type=cache,target=/home/app/.nuget/packages,uid=1654,gid=1654 \
    dotnet publish --configuration Release --output /out

FROM lzocateli/dotnet-aspnet:10.0.14-noble-v1 AS runtime
WORKDIR /app
COPY --from=build --chown=1654:1654 /out .
ENTRYPOINT ["dotnet", "Aplicacao.dll"]
```

## Build local

```bash
docker build --pull --tag lzocateli/dotnet-sdk:10.0.403-noble-v1 dotnet-sdk
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/dotnet-sdk:10.0.403-noble-v1 \
  dotnet-sdk
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `10.0.403-noble-v1` | Imutável | .NET SDK 10.0.403 (runtimes 10.0.14) em Ubuntu 24.04 | Builds versionados e CI |
| `10.0.402-noble-v1` | Imutável | .NET SDK 10.0.402 (runtimes 10.0.13) em Ubuntu 24.04 | Substituir: runtimes afetados por GHSA-p3jp-9v83-76w9 (HIGH, Microsoft.NETCore.App.Runtime) |
| `10.0.400-noble` | Imutável | .NET SDK 10.0.400 em Ubuntu 24.04 | Substituir: runtimes anteriores às correções de segurança da 10.0.13 |

Não há política para `latest`. Uma atualização do SDK, da base, dos pacotes APT ou do contrato exige nova tag imutável e nova validação.

## Validação

Antes da publicação, execute:

```bash
docker buildx build --check --file dotnet-sdk/Dockerfile dotnet-sdk
docker build --pull --tag lzocateli/dotnet-sdk:10.0.403-noble-v1 dotnet-sdk
docker run --rm lzocateli/dotnet-sdk:10.0.403-noble-v1 dotnet --info
docker inspect lzocateli/dotnet-sdk:10.0.403-noble-v1
```

Confirme também os ignores, as duas plataformas, o usuário não root, as ferramentas instaladas, scan de vulnerabilidades, SBOM e proveniência.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `dotnet-sdk`;
- `image_name`: `dotnet-sdk`;
- `image_tag`: `10.0.403-noble-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

O workflow publica no Docker Hub com SBOM e proveniência e pode sincronizar este README. A publicação não ocorre durante o build local.

## Operação e troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `Permission denied` em `/workspace` | bind mount não gravável pelo UID 1654 | `docker run --rm ... id` | ajuste a propriedade/permissão do host sem usar root permanentemente |
| restore retorna `401` | credencial NuGet ausente | execute com logs sem imprimir tokens | forneça a credencial por secret do pipeline |
| `ping: operation not permitted` | runtime removeu a capacidade necessária | revise `cap_drop` e política do host | prefira `curl`; conceda somente a capacidade estritamente necessária |
| aviso `An issue was encountered verifying workloads` | verificação upstream tenta uma operação indisponível ao UID não root | compare `dotnet workload list`; builds comuns continuam funcionando | não execute como root apenas para ocultar o aviso; instale workloads em uma imagem derivada e valide-os explicitamente |

Não há dados persistentes para backup ou restore. Para rollback, volte à tag imutável anterior no pipeline.

## Limitações conhecidas

- As ferramentas de rede aumentam a superfície da imagem e destinam-se somente a diagnóstico durante builds.
- A imagem não oferece daemon Docker nem suporte a Docker-in-Docker.
- Em 2026-11-04, o Trivy 0.72.0 não encontrou vulnerabilidades corrigíveis `CRITICAL` ou `HIGH` na imagem local `linux/amd64` (.NET SDK 10.0.403, runtimes 10.0.14 e `libbrotli1` atualizado). Não promova esta imagem a runtime e repita o scan antes da publicação.
- Pacotes APT são resolvidos no build; registre o digest publicado e reconstrua sob nova tag após atualizações.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem oficial .NET SDK | 10.0 / Ubuntu Noble | MIT e licenças dos componentes distribuídos | `https://github.com/dotnet/dotnet-docker` |
| Pacotes Ubuntu | Noble | Licenças próprias de cada pacote | `https://packages.ubuntu.com/noble/` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `10.0.403-noble-v1`: atualização para .NET SDK 10.0.403, par oficial do .NET 10.0.14, que corrige GHSA-p3jp-9v83-76w9 (HIGH, Microsoft.NETCore.App.Runtime); `libbrotli1` atualizado para corrigir a CVE-2026-111497 (HIGH).
- `10.0.402-noble-v1`: atualização para .NET SDK 10.0.402, par oficial do .NET 10.0.13 (atualização de segurança de 2026-10-13); primeira tag no formato `<versao-upstream>-vN`.
- `10.0.400-noble`: atualização para .NET SDK 10.0.400 com imagem base oficial fixada por digest.
- `10.0.302-noble`: migração para .NET 10, execução não root, ferramentas de diagnóstico e metadados OCI.