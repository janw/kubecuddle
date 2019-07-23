#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

current_dir=$(dirname $0)
bash "$current_dir/create_kubeconfig.sh"

exec $@
