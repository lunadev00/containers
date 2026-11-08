<!--
SPDX-FileCopyrightText: 2024 Lincoln Zocateli
SPDX-License-Identifier: MIT
-->

# rust

![Docker Hub](https://img.shields.io/badge/image-lzocateli%2Frust-2496ED?logo=docker&logoColor=white)
![Version](https://img.shields.io/badge/version-1.99.1--bookworm--v1-2E7D32)
![Base](https://img.shields.io/badge/base-rust%3A1.99.1--slim--bookworm-555555?logo=docker&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-linux%2Famd64-607D8B)
![Repository code license](https://img.shields.io/badge/repository_code-MIT-1565C0)
![Build](https://img.shields.io/badge/build-validado-success)

Rust no canal stable para builds e testes em contêineres, com alvo WebAssembly, `wasm-bindgen-cli`, fuzzing com `cargo-afl` (sem nightly) e bibliotecas de libsodium e OpenSSL para testes diferenciais de criptografia. Em relação à imagem oficial, adiciona essas ferramentas e executa como usuário não root, com caches do cargo no home desse usuário.

## Referência da imagem

| Item | Valor |
| --- | --- |
| Imagem | `lzocateli/rust:1.99.1-bookworm-v1` |
| Imagem base | `rust:1.99.1-slim-bookworm` (fixada por digest) |
| Plataformas | `linux/amd64` |
| Usuário padrão | `10001:10001` (`rust`) |
| Entry point | nenhum; `CMD ["cargo", "--version"]` |
| Diretório de trabalho | `/workspace` |
| Código-fonte | `https://github.com/lzocateli/containers/tree/main/rust` |
| Documentação | `https://github.com/lzocateli/containers/tree/main/rust` |

## Conteúdo e finalidade

### Incluído

- Rust 1.99.1 (stable), com `clippy`, `rustfmt` e alvo `wasm32-unknown-unknown`.
- `wasm-bindgen-cli` 0.2.130: a versão precisa ser igual à da crate `wasm-bindgen` do projeto.
- `cargo-afl` 0.18.2, com o AFL++ já compilado no canal stable.
- `clang`, `make`, `pkg-config`, `libsodium-dev` e `libssl-dev`.

### Não incluído

- Toolchain nightly, `cargo-fuzz` e o recurso `plugins` do afl.rs, que exigem nightly.
- Alvos Windows, macOS, Android e iOS.

## Início rápido

```bash
docker pull lzocateli/rust:1.99.1-bookworm-v1
docker run --rm lzocateli/rust:1.99.1-bookworm-v1
```

Rodar os testes de um workspace:

```bash
docker run --rm \
  --volume "$PWD:/workspace" \
  lzocateli/rust:1.99.1-bookworm-v1 \
  cargo test --workspace --locked
```

## Docker Compose

```yaml
services:
  core-tests:
    image: lzocateli/rust:1.99.1-bookworm-v1
    working_dir: /workspace
    volumes:
      - ./core:/workspace
      - cargo-cache:/home/rust/.cargo/registry
    command: ["cargo", "test", "--workspace", "--locked"]
volumes:
  cargo-cache:
```

## Configuração

### Variáveis de ambiente

| Variável | Obrigatória | Secreta | Padrão | Descrição |
| --- | --- | --- | --- | --- |
| `CARGO_HOME` | Não | Não | `/home/rust/.cargo` | Registro, git e caches do cargo, graváveis pelo usuário `rust`. |

### Portas

A imagem não expõe portas.

### Persistência e mounts

| Caminho no contêiner | Modo | Conteúdo | Backup necessário |
| --- | --- | --- | --- |
| `/workspace` | `rw` | Código-fonte e `target/` | Não (fonte no Git) |
| `/home/rust/.cargo/registry` | `rw` | Cache de crates (opcional) | Não |

O usuário `10001` precisa de escrita no diretório montado.

### Secrets

Registros privados de crates devem usar `--mount=type=secret` do BuildKit ou tokens injetados pelo CI. Nunca use `ARG` ou `ENV`.

## Inicialização e ciclo de vida

Cada execução roda um comando e termina. Não há health check.

## Segurança

- Executa como usuário não root `rust` (`10001`); o toolchain em `/usr/local/cargo` e `/usr/local/rustup` é somente leitura para ele.
- Contém compiladores por finalidade; use somente em build e CI.
- `cargo afl fuzz` pode exigir ajustes no host (`core_pattern`); veja *Troubleshooting*.

## Build local

```bash
docker build \
  --pull \
  --tag lzocateli/rust:1.99.1-bookworm-v1 \
  rust
```

## Tags e compatibilidade

| Tag | Mutabilidade | Compatibilidade | Uso recomendado |
| --- | --- | --- | --- |
| `1.99.1-bookworm-v1` | Imutável | Rust 1.99.1, wasm-bindgen 0.2.130, cargo-afl 0.18.2 | CI e builds |

Uma nova versão do Rust gera nova tag. Uma troca de `wasm-bindgen-cli` ou `cargo-afl` com o mesmo Rust incrementa `vN`.

## Validação

Antes da publicação, confirme:

- `.gitignore` e `.dockerignore` presentes;
- análise do Dockerfile com BuildKit;
- `bash rust/scripts/smoke-test.sh --image <ref>`, que verifica o usuário não root, as versões, o alvo wasm32, o cargo-afl, libsodium e OpenSSL e o build de uma crate para wasm32;
- inspeção de vulnerabilidades com `tools/scripts/scan-container-vulnerabilities.ps1 -ContextPath rust`;
- SBOM e proveniência na publicação.

## Publicação

Use **Actions > Publicar imagem de container > Run workflow** e informe:

- `context_path`: `rust`;
- `image_name`: `rust`;
- `image_tag`: `1.99.1-bookworm-v1`;
- `dockerfile`: `Dockerfile`;
- `platforms`: `linux/amd64`.

## Operação

Atualize a cada release stable do Rust (ciclo de seis semanas) e alinhe `wasm-bindgen-cli` com a versão usada pelos projetos consumidores.

## Troubleshooting

| Sintoma | Causa provável | Verificação | Correção |
| --- | --- | --- | --- |
| `wasm-bindgen` recusa o binário | Versão da crate diferente da CLI | `wasm-bindgen --version` e `Cargo.lock` | Use a tag cuja CLI corresponde à crate |
| `cargo afl fuzz` aborta por `core_pattern` | Configuração do kernel do host | `cat /proc/sys/kernel/core_pattern` | Defina `AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1` na execução ou ajuste o host |
| `Permission denied` em `target/` | Mount sem escrita para o UID 10001 | `ls -ln` no host | Ajuste o dono ou use `--user` compatível |

## Limitações conhecidas

- Publicada somente para `linux/amd64` nesta versão.

## Licenças e fontes

| Componente | Versão | Licença | Fonte |
| --- | --- | --- | --- |
| Conteúdo original deste repositório | Atual | MIT | `https://github.com/lzocateli/containers` |
| Rust e imagem base `rust:1.99.1-slim-bookworm` | 1.99.1 | MIT OR Apache-2.0 | `https://hub.docker.com/_/rust` |
| wasm-bindgen-cli | 0.2.130 | MIT OR Apache-2.0 | `https://github.com/rustwasm/wasm-bindgen` |
| cargo-afl / AFL++ | 0.18.2 | Apache-2.0 | `https://github.com/rust-fuzz/afl.rs` |
| libsodium | pacote Debian bookworm | ISC | `https://libsodium.org` |
| OpenSSL | pacote Debian bookworm | Apache-2.0 | `https://www.openssl.org` |

O badge MIT descreve somente o conteúdo original deste repositório. A imagem inclui componentes de terceiros que permanecem sujeitos aos termos e avisos de suas fontes. Consulte a [política de licenciamento](https://github.com/lzocateli/containers/blob/main/LICENSING.md), preserve as atribuições upstream e verifique também os avisos distribuídos dentro da imagem.

## Histórico de alterações

- `1.99.1-bookworm-v1`: primeira versão.
