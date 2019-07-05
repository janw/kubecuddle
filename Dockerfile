FROM ubuntu:bionic

ENV GID=1042
ENV UID=1042

WORKDIR /tmp
COPY keys/ ./

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y ca-certificates apt-transport-https gnupg2

RUN \
    apt-key add ./*.gpg && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubecuddle.list

RUN \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    # Basic shell tooling
    wget curl screen git zsh bash vim-tiny sudo zgen \
    # Kubernetes tools
    kubectl \
    # Miscellaneous tools
    jq \
    # Cleanup
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

ENV TINI_VERSION v0.18.0
RUN \
    wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" && \
    chmod +x /usr/local/bin/tini

RUN \
    # Kustomize
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs curl -O -L && \
    mv kustomize_*_linux_amd64 /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize && \
    \
    # Helm
    curl -L https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz | tar -zx && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    \
    # Stern
    curl -s https://api.github.com/repos/wercker/stern/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs curl -O -L && \
    mv stern_linux_amd64 /usr/local/bin/stern && \
    chmod +x /usr/local/bin/stern

RUN rm -rf /tmp/*
WORKDIR /home/cuddle
RUN \
    groupadd --gid $GID cuddle && \
    useradd --gid $GID --uid $UID -d /home/cuddle cuddle && \
    usermod -aG sudo cuddle && \
    echo "cuddle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY rc-files/ ./
RUN chown -R cuddle:cuddle /home/cuddle
USER cuddle
RUN \
    zsh -c "source ~/.zshrc"

ENTRYPOINT [ "zsh" ]
