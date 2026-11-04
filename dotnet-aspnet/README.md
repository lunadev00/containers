<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# ASP.NET Core 10 Runtime

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fdotnet--aspnet-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-10.0.14--noble--v1-2E7D32)
![Base](https://img.shields.io/badge/base-dotnet%2Faspnet%3A10.0--noble-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-BuildKit-success)

Imagem base do ASP.NET Core 10 em Ubuntu 24.04 para executar aplicações framework-dependent em ambientes produtivos. Mantém a compatibilidade da variante Noble oficial, inicia como usuário não root e não inclui o SDK nem ferramentas adicionais.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/dotnet-aspnet:10.0.14-noble-v1` |
| Imagem base | Digest do manifest multi-arquitetura de `mcr.microsoft.com/dotnet/aspnet:10.0-noble` |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `1654:1654` (`APP_UID` da imagem oficial) |
| Entry point | `dotnet` |
| Comando padrão | `--info` |
| Diretório de trabalho | `/app` |
| Porta | `8080/tcp` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/dotnet-aspnet` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/dotnet-aspnet` |

## Conteúdo e finalidade

### Incluído

- Microsoft.AspNetCore.App 10.0.14;
- Microsoft.NETCore.App 10.0.14;
- bibliotecas do Ubuntu Noble presentes na imagem oficial;
- diretório `/app` gravável pelo usuário não root.

### Não incluído

- .NET SDK, compiladores ou ferramentas de build;
- aplicação, migrations ou scripts de bootstrap;
- shell administrativo adicional, clientes de banco ou ferramentas de diagnóstico;
- certificados privados, credenciais ou configuração de ambiente;
- health check genérico, pois a rota de saúde pertence à aplicação derivada.

## Início rápido

```bash
docker pull lzocateli/dotnet-aspnet:10.0.14-noble-v1
docker run --rm lzocateli/dotnet-aspnet:10.0.14-noble-v1
```

Para executar uma aplicação publicada em `./out`:

```bash
docker run --rm \
  --publish 127.0.0.1:8080:8080 \
  --volume "$PWD/out:/app:ro" \
  lzocateli/dotnet-aspnet:10.0.14-noble-v1 \
  Aplicacao.dll
```

## Imagem de aplicação

Use esta imagem como estágio final e copie somente os artefatos publicados:

```dockerfile
# syntax=docker/dockerfile:1
FROM lzocateli/dotnet-sdk:10.0.400-noble AS build
WORKDIR /workspace
COPY --chown=1654:1654 . .
RUN --mount=type=cache,target=/home/app/.nuget/packages,uid=1654,gid=1654 \
    dotnet publish --configuration Release --output /out

FROM lzocateli/dotnet-aspnet:10.0.14-noble-v1 AS runtime
COPY --from=build --chown=1654:1654 /out .
CMD ["Aplicacao.dll"]
```

O entrypoint já é `dotnet`; por isso a imagem derivada informa somente a DLL em `CMD`.

## Docker Compose

```yaml
services:
  app:
    image: exemplo/aplicacao:1.0.0
    restart: unless-stopped
    read_only: true
    init: true
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      ASPNETCORE_HTTP_PORTS: "8080"
      DOTNET_EnableDiagnostics: "0"
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=64m
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `ASPNETCORE_HTTP_PORTS` | Não | Não | `8080` | Portas HTTP usadas pelo Kestrel quando a aplicação não as sobrescreve. |
| `ASPNETCORE_ENVIRONMENT` | Não | Não | `Production` quando ausente | Ambiente lógico da aplicação. Não armazene secrets nesta variável. |
| `DOTNET_EnableDiagnostics` | Não | Não | habilitado pelo runtime | Use `0` quando diagnósticos externos não forem necessários. |

Outras variáveis `DOTNET_*` e `ASPNETCORE_*` seguem a documentação oficial. Strings de conexão, tokens e chaves devem ser fornecidos por secrets do orquestrador ou arquivos montados, nunca incorporados à imagem.

### Portas, persistência e mounts

| Item | Contrato |
| --- | --- |
| `8080/tcp` | HTTP interno; publique somente via proxy ou rede necessária. |
| `/app` | Artefatos imutáveis da aplicação; prefira conteúdo copiado na imagem ou mount somente leitura. |
| `/tmp` | Temporários de runtime; use `tmpfs` quando o filesystem for somente leitura. |

A imagem não declara `VOLUME` e não mantém dados persistentes. Dados de negócio, Data Protection keys e uploads exigem armazenamento externo ou mount explicitamente projetado pela aplicação.

## Inicialização e ciclo de vida

O processo `dotnet` é o PID 1 e recebe diretamente `SIGTERM`. A aplicação deve encerrar dentro do período de tolerância do orquestrador. Migrations devem ocorrer em job controlado e idempotente, não implicitamente em todas as réplicas.

Defina o health check na imagem da aplicação ou no orquestrador usando uma rota que verifique a prontidão real. Esta base não instala `curl` e não presume endpoint, protocolo ou dependências.

## Segurança

- executa por padrão como UID/GID `1654:1654`;
- não requer root, modo privilegiado ou capacidades Linux adicionais;
- suporta `read_only`, `no-new-privileges` e remoção de todas as capabilities quando a aplicação não exigir escrita fora de `/tmp`;
- não contém SDK nem pacotes adicionais além da base oficial;
- a base é fixada por digest e deve ser atualizada para receber correções upstream;
- publique TLS no proxy/ingress e não inclua chaves privadas na imagem.

## Build local

```bash
docker build --pull --tag lzocateli/dotnet-aspnet:10.0.14-noble-v1 dotnet-aspnet
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/dotnet-aspnet:10.0.14-noble-v1 \
  dotnet-aspnet
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `10.0.14-noble-v1` | Imutável | ASP.NET Core 10.0.14 em Ubuntu 24.04 | Runtime produtivo framework-dependent |
| `10.0.13-noble-v1` | Imutável | ASP.NET Core 10.0.13 em Ubuntu 24.04 | Substituir: afetada por GHSA-p3jp-9v83-76w9 (HIGH, Microsoft.NETCore.App.Runtime) |
| `10.0.11-noble` | Imutável | ASP.NET Core 10.0.11 em Ubuntu 24.04 | Substituir: afetada por CVE-2026-70188 e CVE-2026-88092 |

Não há política para `latest`. Uma atualização do runtime, da base ou do contrato exige nova tag imutável, rebuild da aplicação e validação antes do rollout.

## Validação

Antes da publicação, execute:

```bash
docker buildx build --check --file dotnet-aspnet/Dockerfile dotnet-aspnet
docker build --pull --tag lzocateli/dotnet-aspnet:10.0.14-noble-v1 dotnet-aspnet
docker run --rm lzocateli/dotnet-aspnet:10.0.14-noble-v1
docker inspect lzocateli/dotnet-aspnet:10.0.14-noble-v1
```

Além do smoke test da base, construa uma aplicação mínima com o SDK correspondente e valide HTTP, sinais, execução não root e filesystem somente leitura. Na release, execute scan de vulnerabilidades e confira SBOM, proveniência, labels e manifests das plataformas.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** com:

- `context_path`: `dotnet-aspnet`;
- `image_name`: `dotnet-aspnet`;
- `image_tag`: `10.0.14-noble-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

O workflow publica no Docker Hub com SBOM e proveniência e pode sincronizar este README. A publicação não ocorre durante o build local.

## Operação e troubleshooting

Atualize reconstruindo a aplicação sobre uma nova tag imutável; faça rollout gradual e mantenha a imagem anterior para rollback. Logs devem ir para stdout/stderr. CPU, memória, réplicas, probes e limites são definidos pela aplicação e pelo orquestrador.

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `The application ... does not exist` | DLL incorreta ou ausente em `/app` | inspecione os artefatos do estágio de publish | ajuste `COPY` e `CMD` da imagem derivada |
| falha ao gravar arquivo | filesystem somente leitura ou UID sem permissão | verifique o caminho e o UID 1654 | use `/tmp` ou mount dedicado com propriedade correta |
| aplicação não responde em 8080 | aplicação sobrescreveu a URL/porta | revise `ASPNETCORE_HTTP_PORTS` e logs | alinhe a porta da aplicação, imagem e orquestrador |

## Limitações conhecidas

- A imagem é uma base de runtime; não é um serviço útil sem uma aplicação ASP.NET Core publicada.
- Não inclui utilitários para health check. Use probes nativas do orquestrador ou adicione uma ferramenta mínima na imagem derivada quando indispensável.
- A variante Ubuntu Noble prioriza compatibilidade e é maior que variantes chiseled.
- Em 2026-11-04, o Trivy 0.72.0 não encontrou vulnerabilidades corrigíveis `CRITICAL` ou `HIGH` na imagem local `linux/amd64` (Ubuntu 24.04, Microsoft.AspNetCore.App e Microsoft.NETCore.App 10.0.14); repita o scan sobre o digest publicado antes do rollout.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Imagem oficial ASP.NET Core | 10.0.14 / Ubuntu Noble | MIT e licenças dos componentes distribuídos | `https://github.com/dotnet/dotnet-docker` |
| Ubuntu | 24.04 Noble | Licenças próprias dos pacotes distribuídos | `https://packages.ubuntu.com/noble/` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `10.0.14-noble-v1`: atualização para ASP.NET Core 10.0.14, que corrige GHSA-p3jp-9v83-76w9 (HIGH, Microsoft.NETCore.App.Runtime).
- `10.0.13-noble-v1`: atualização para ASP.NET Core 10.0.13, que corrige CVE-2026-70188 e CVE-2026-88092 (críticas, ASP.NET Core); primeira tag no formato `<versao-upstream>-vN`.
- `10.0.11-noble`: atualização para ASP.NET Core 10.0.11 com imagem base oficial fixada por digest.
- `10.0.10-noble`: migração para ASP.NET Core 10, execução não root, porta 8080 e metadados OCI.