FROM ubuntu:bionic

WORKDIR /tmp
COPY keys/ ./

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y ca-certificates apt-transport-https gnupg2 && \
    apt-key add ./*.gpg && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubecuddle.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
        apt-get install -y \
            # Basic shell tooling
            wget curl screen git zsh bash vim-nox zgen \
            # Kubernetes tools
            kubectl \
            # Miscellaneous tools
            jq \
    && \
    # Tini
    curl -s https://api.github.com/repos/krallin/tini/releases/latest |\
        grep browser_download | grep 'tini\"' | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini && \
    # Kustomize
    curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize && \
    # Helm
    curl -s https://api.github.com/repos/helm/helm/releases/latest |\
        sed -nE 's/.*(https:\/\/get\.helm\.sh\/helm-.+-linux-amd64.tar.gz).*/\1/p' | head -1 |\
        xargs wget -nv -O /tmp/helm.tar.gz && \
    tar -zxf /tmp/helm.tar.gz && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    # Stern
    curl -s https://api.github.com/repos/wercker/stern/releases/latest |\
        grep browser_download | grep linux | cut -d '"' -f 4 | xargs wget -nv -O /usr/local/bin/stern && \
    chmod +x /usr/local/bin/stern && \
    # Gotty
    curl -s https://api.github.com/repos/yudai/gotty/releases/latest |\
        grep browser_download | grep linux_amd64 | cut -d '"' -f 4 | xargs wget -nv -O /tmp/gotty.tar.gz && \
    tar -zxf /tmp/gotty.tar.gz && \
    mv /tmp/gotty /usr/local/bin/gotty && \
    chmod +x /usr/local/bin/gotty

ARG GID=1042
ARG UID=1042
ARG USERNAME=cuddle
ARG GROUPNAME=$USERNAME
ARG ALLOW_SUDO

WORKDIR /home/$USERNAME
COPY scripts/ /scripts
COPY rc-files/ ./

RUN \
    # Create user
    groupadd --gid $GID $GROUPNAME && \
    useradd --gid $GID --uid $UID -d /home/${USERNAME} $USERNAME && \
    # Add user to sudoers if requested by build-arg
    [ ! -n "$ALLOW_SUDO" ] || ( \
        apt-get install -y sudo && \
        usermod -aG sudo $USERNAME && \
        echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    ) && \
    # Cleanup
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    # Ensure home ownership
    chown -R $USERNAME:$GROUPNAME /home/$USERNAME && \
    chmod +x /scripts/*

# Drop privileges and make ourselves at home.
USER $USERNAME
ENV HOST=$USERNAME
RUN zsh -c "source ~/.zshrc"

ENTRYPOINT [ "tini", "--", "/scripts/entrypoint.sh" ]
CMD [ "zsh" ]
