<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# promtool

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Fpromtool-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-3.13.5--v1-2E7D32)
![Base](https://img.shields.io/badge/base-prom%2Fprometheus%3Av3.13.5-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64%20%7C%20linux%2Farm64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Executa o `promtool` do Prometheus 3.13, a linha LTS vigente, para validar e testar regras de alerta e de gravação em pipelines e testes locais. A diferença em relação à imagem base é o entrypoint: `promtool` no lugar do servidor Prometheus, com usuário `nobody` explícito.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/promtool:3.13.5-v1` |
| Imagem base | `prom/prometheus:v3.13.5` (fixada por digest) |
| Plataformas | `linux/amd64`, `linux/arm64` |
| Usuário padrão | `65534:65534` (`nobody`) |
| Entry point | `/bin/promtool` |
| Diretório de trabalho | `/work` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/promtool` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/promtool` |

## Conteúdo e finalidade

### Incluído

- `promtool` 3.13.5 (Prometheus LTS).

### Não incluído

- Servidor Prometheus em execução, armazenamento TSDB ou configuração de scrape.

## Início rápido

```bash
docker pull lzocateli/promtool:3.13.5-v1
docker run --rm lzocateli/promtool:3.13.5-v1 --version
```

Testar regras de um diretório local (somente leitura):

```bash
docker run --rm --read-only \
  --volume "$PWD/deploy/observability:/work:ro" \
  lzocateli/promtool:3.13.5-v1 test rules /work/alertas.test.yml
```

## Docker Compose

```yaml
services:
  promtool:
    image: lzocateli/promtool:3.13.5-v1
    read_only: true
    working_dir: /work
    volumes:
      - ./deploy/observability:/work:ro
    command: ["test", "rules", "alertas.test.yml"]
```

## Configuração

### Variáveis de ambiente

A imagem não usa variáveis de ambiente.

### Portas

A imagem não expõe portas.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/work` | `ro` | Arquivos de regras e testes a validar | Não |

### Secrets

Não há secrets. Não monte arquivos com credenciais.

## Inicialização e ciclo de vida

Cada execução roda um único comando `promtool` e termina com o código de saída dele. Não há health check, porque o processo é efêmero.

## Segurança

- Executa como `nobody`; compatível com `--read-only`.
- Não precisa de rede; use `--network none` em CI.
- A base é a imagem oficial do Prometheus, fixada por digest e atualizada a cada patch da linha LTS.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/promtool:3.13.5-v1 \
  promtool
```

Para múltiplas plataformas:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag lzocateli/promtool:3.13.5-v1 \
  promtool
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `3.13.5-v1` | Imutável | Sintaxe de regras do Prometheus 3.13 | CI e testes |

Patches da linha 3.13 LTS geram nova tag (`3.13.N-v1`). A troca de linha LTS gera nova tag e é anunciada no histórico.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes;
- análise do Dockerfile com BuildKit;
- `bash promtool/scripts/smoke-test.sh --image <ref>` (verifica usuário, entrypoint, versão, `check rules` e `test rules`);
- inspeção de vulnerabilidades com `tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath promtool`;
- geração de SBOM e proveniência na publicação.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `promtool`;
- `image_name`: `promtool`;
- `image_tag`: `3.13.5-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64,linux/arm64`.

## Operação

Atualize quando houver patch da linha 3.13 LTS e migre para a próxima LTS antes do fim do suporte (31 de julho de 2027, segundo endoflife.date).

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `permission denied` ao ler regras | Arquivos sem leitura para outros usuários | `ls -l` no host | Conceda leitura (`chmod o+r`) ou ajuste o mount |
| `could not find rule file` | Caminho relativo diferente de `/work` | Conferir `rule_files` do teste | Use caminhos relativos ao arquivo de teste |

## Limitações conhecidas

- A imagem contém também os demais binários da imagem base do Prometheus; apenas o `promtool` faz parte do contrato.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Prometheus e promtool | 3.13.5 | Apache-2.0 | `https://github.com/prometheus/prometheus` |
| Imagem base | `prom/prometheus:v3.13.5` | Apache-2.0 | `https://hub.docker.com/r/prom/prometheus` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `3.13.5-v1`: primeira versão, com promtool 3.13.5 LTS.
