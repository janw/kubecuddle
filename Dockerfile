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
    wget curl screen git zsh bash vim-nox sudo zgen \
    # Kubernetes tools
    kubectl \
    # Miscellaneous tools
    jq \
    # Cleanup
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

RUN \
    # Tini
    curl -s https://api.github.com/repos/krallin/tini/releases/latest |\
        grep browser_download | grep 'tini\"' | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini && \
    # Kustomize
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize && \
    \
    # Helm
    curl -s https://api.github.com/repos/helm/helm/releases/latest |\
        sed -nE 's/.*(https:\/\/get\.helm\.sh\/helm-.+-linux-amd64.tar.gz).*/\1/p' | head -1 |\
        xargs wget -nv -O /tmp/helm.tar.gz && \
    tar -zxf /tmp/helm.tar.gz && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    \
    # Stern
    curl -s https://api.github.com/repos/wercker/stern/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/stern && \
    chmod +x /usr/local/bin/stern

COPY scripts /scripts

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
