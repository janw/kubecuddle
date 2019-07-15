#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

filename=${1:-"/home/cuddle/.kube/config"}

if [ -f "$filename" ]; then
    echo "$filename exists."
    exit 0
fi

if [ ! -d /var/run/secrets/kubernetes.io/serviceaccount ]; then
    echo "Not in a Pod."
    exit 0
fi

if [ -z "${BEARER_TOKEN:-}" ]; then
    echo "No BEARER_TOKEN given."
    exit 0
fi

mkdir -p "$(dirname "$filename")"
cat <<EOF > "$filename"
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    server: https://kubernetes.default.svc
  name: local
contexts:
- context:
    cluster: local
    namespace: default
    user: local
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: local
  user:
    token: ${BEARER_TOKEN:-}
EOF

echo "Created $filename."
