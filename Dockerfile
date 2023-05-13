FROM ubuntu:jammy
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

WORKDIR /tmp
COPY keys/ ./

# hadolint ignore=DL3008
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends -y ca-certificates apt-transport-https gnupg2 && \
    apt-key add ./*.gpg && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubecuddle.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
        apt-get install --no-install-recommends -y \
            # Basic shell tooling
            wget curl screen git zsh bash vim-nox zgen \
            # Kubernetes tools
            kubectl \
            # Miscellaneous tools
            jq \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Tini
RUN \
    curl -SsL --fail https://api.github.com/repos/krallin/tini/releases/latest |\
        jq -re '[ .assets[] | select(.name | test("amd64")) ][0].browser_download_url' |\
        xargs wget -nv -O /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Kustomize
RUN \
    curl -SsL --fail https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest  |\
        jq -re '[ .assets[] | select(.name | test("linux")) ][0].browser_download_url' |\
        xargs wget -nv -O /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize

# Helm
RUN \
    curl -SsL --fail https://api.github.com/repos/helm/helm/releases/latest |\
        sed -nE 's/.*(https:\/\/get\.helm\.sh\/helm-.+-linux-amd64.tar.gz).*/\1/p' | head -1 |\
        xargs wget -nv -O /tmp/helm.tar.gz && \
    tar -zxf /tmp/helm.tar.gz && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm

# Stern
RUN \
    curl -SsL --fail https://api.github.com/repos/stern/stern/releases/latest  |\
        jq -re '[ .assets[] | select(.name | test("linux")) ][0].browser_download_url' |\
        xargs wget -nv -O /usr/local/bin/stern && \
    chmod +x /usr/local/bin/stern

# Gotty
RUN \
    curl -SsL --fail https://api.github.com/repos/yudai/gotty/releases/latest  |\
        jq -re '[ .assets[] | select(.name | test("linux_amd64")) ][0].browser_download_url' |\
        xargs wget -nv -O /tmp/gotty.tar.gz && \
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

# hadolint ignore=DL3008
RUN \
    # Create user
    groupadd --gid $GID $GROUPNAME && \
    useradd --gid $GID --uid $UID -d /home/${USERNAME} $USERNAME && \
    # Add user to sudoers if requested by build-arg
    [ -z "$ALLOW_SUDO" ] || ( \
        apt-get install --no-install-recommends -y sudo && \
        usermod -aG sudo $USERNAME && \
        echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    ) && \
    # Cleanup
    apt-get clean && \
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
