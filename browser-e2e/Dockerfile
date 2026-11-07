# syntax=docker/dockerfile:1

ARG NODE_IMAGE="lzocateli/node:24.22.1-bookworm-v1@sha256:56a1716449d2054cf58c69d2365986be75260fb85e7b4a251e08e26a3ebc2c80"

FROM ${NODE_IMAGE} AS runtime

ARG IMAGE_VERSION="1.65.0-v1"
ARG PLAYWRIGHT_VERSION=1.65.0
ARG SELENIUM_WEBDRIVER_VERSION=4.52.0
ARG GECKODRIVER_VERSION=0.37.1
ARG GECKODRIVER_SHA256=e815130ea95983e162ae91843b48d3a3ce991735635fce83a647afde21e09f7e

LABEL org.opencontainers.image.title="lzocateli/browser-e2e" \
	org.opencontainers.image.description="Testes E2E em Node.js 24 LTS com Playwright (Chrome, Edge e Brave estáveis) e Selenium com geckodriver (Firefox ESR e estável), inclusive extensões de navegador." \
	org.opencontainers.image.source="https://github.com/lzocateli/containers" \
	org.opencontainers.image.documentation="https://github.com/lzocateli/containers/tree/main/browser-e2e" \
	org.opencontainers.image.url="https://github.com/lzocateli/containers/tree/main/browser-e2e" \
	org.opencontainers.image.version="${IMAGE_VERSION}"

USER root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Repositórios oficiais: Brave (canal stable) e Mozilla (firefox estável e firefox-esr).
RUN apt-get update \
	&& apt-get install --yes --no-install-recommends ca-certificates curl gnupg xvfb \
	&& install --directory --mode=0755 /etc/apt/keyrings \
	&& curl --proto '=https' --tlsv1.2 -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
		--output /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
		> /etc/apt/sources.list.d/brave-browser-release.list \
	&& curl --proto '=https' --tlsv1.2 -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
		| gpg --dearmor --output /etc/apt/keyrings/packages.mozilla.org.gpg \
	&& echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" \
		> /etc/apt/sources.list.d/mozilla.list \
	&& printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
	&& apt-get update \
	&& apt-get install --yes --no-install-recommends brave-browser firefox firefox-esr \
	&& rm -rf /var/lib/apt/lists/*

# O BuildKit confere o SHA-256 do geckodriver antes de usar o arquivo.
ADD --checksum=sha256:${GECKODRIVER_SHA256} \
	"https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" \
	/tmp/geckodriver.tar.gz

# Pacotes npm sem scripts de ciclo de vida; o Playwright instala Chrome e Edge estáveis
# (canais de marca) e as dependências de sistema pelo binário já instalado, sem npx.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN npm install --global --ignore-scripts "playwright@${PLAYWRIGHT_VERSION}" "@playwright/test@${PLAYWRIGHT_VERSION}" \
		"selenium-webdriver@${SELENIUM_WEBDRIVER_VERSION}" \
	&& playwright install --with-deps chrome msedge \
	&& npm cache clean --force \
	&& rm -rf /var/lib/apt/lists/* \
	&& tar --extract --gzip --file /tmp/geckodriver.tar.gz --directory /usr/local/bin geckodriver \
	&& rm /tmp/geckodriver.tar.gz \
	&& install --directory --owner=node --group=node /workspace

ENV NODE_PATH=/usr/local/lib/node_modules \
	BRAVE_EXECUTABLE=/usr/bin/brave-browser \
	FIREFOX_EXECUTABLE=/usr/bin/firefox \
	FIREFOX_ESR_EXECUTABLE=/usr/bin/firefox-esr

WORKDIR /workspace

USER node:node

CMD ["playwright", "--version"]
