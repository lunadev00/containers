ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0.427-jammy

RUN apt update -y && apt upgrade -y \
 && apt install -y \
    gpg \
    jq \
    lsb-release \
    fzf \
    zip unzip \
    python3-pip \
    net-tools iputils-ping curl wget \
    libxml2-dev

RUN pip install --upgrade pip

ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt install -y zsh

RUN sh -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"

RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

RUN echo "plugins=(zsh-autosuggestions)" >> ~/.zshrc \
 && echo 'HISTFILE=~/.histfile' >> ~/.zshrc

# RUN dotnet dev-certs https --trust; dotnet dev-certs https -ep "/root/.aspnet/https/aspnetapp.pfx" -p "SecurePwdGoesHere"
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
