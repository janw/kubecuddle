#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

filename=${1:-"/home/cuddle/.kube/config"}

if [ ! -d /var/run/secrets/kubernetes.io/serviceaccount ]; then
    echo "Not in a Pod."
    exit 0
fi

if [ -f "$filename" ]; then
    echo "$filename exists."
    exit 0
fi

mkdir -p "$(dirname "$filename")"
printf 'apiVersion: v1\nkind: Config\nclusters:\n- cluster:\n    certificate-authority-data: ' > $filename
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | base64 | xargs printf '%s' >> $filename
printf '\n    server: https://kubernetes.default.svc\n  name: local\ncontexts:\n- context:\n' >> $filename
cat /var/run/secrets/kubernetes.io/serviceaccount/namespace | \
    xargs printf '    cluster: local\n    namespace: %s\n    user: webshell\n  name: local\n' >> $filename
printf 'current-context: local\npreferences: {}\nusers:\n- name: webshell\n  user:\n    token: ' >> $filename
cat /var/run/secrets/kubernetes.io/serviceaccount/token | xargs printf '%s\n' >> $filename

echo "Created $filename."
