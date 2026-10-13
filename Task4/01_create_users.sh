#!/usr/bin/env bash
set -euo pipefail

# Creates Kubernetes users (x509 client certs) and personal kubeconfigs.
# Prerequisites:
# 1) minikube is running and kubectl points to this cluster
# 2) ~/.minikube/ca.crt and ~/.minikube/ca.key are accessible

MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
VALID_DAYS="${VALID_DAYS:-365}"
OUT_DIR="${OUT_DIR:-./Task4/generated-users}"
CA_CRT="${CA_CRT:-$HOME/.minikube/ca.crt}"
CA_KEY="${CA_KEY:-$HOME/.minikube/ca.key}"

USERS=(
  "pavel.platform.admin:grp-platform-admins"
  "sofiya.security.audit:grp-security-auditors"
  "anna.payments.viewer:grp-payments-viewers"
  "boris.payments.engineer:grp-payments-engineers"
  "irina.logistics.viewer:grp-logistics-viewers"
  "nikita.logistics.engineer:grp-logistics-engineers"
)

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is required but not installed." >&2
    exit 1
  }
}

require_cmd kubectl
require_cmd openssl
require_cmd minikube

if [[ ! -f "$CA_CRT" || ! -f "$CA_KEY" ]]; then
  echo "Error: Minikube CA files were not found:" >&2
  echo "  CA_CRT=$CA_CRT" >&2
  echo "  CA_KEY=$CA_KEY" >&2
  exit 1
fi

kubectl config use-context "$MINIKUBE_PROFILE" >/dev/null 2>&1 || true

CLUSTER_NAME="$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')"
API_SERVER="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"

if [[ -z "$CLUSTER_NAME" || -z "$API_SERVER" ]]; then
  echo "Error: Unable to detect active kubectl context cluster/server." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

for pair in "${USERS[@]}"; do
  user="${pair%%:*}"
  group="${pair##*:}"

  user_dir="$OUT_DIR/$user"
  mkdir -p "$user_dir"

  key_file="$user_dir/$user.key"
  csr_file="$user_dir/$user.csr"
  crt_file="$user_dir/$user.crt"
  kubeconfig_file="$user_dir/$user.kubeconfig"

  openssl genrsa -out "$key_file" 2048 >/dev/null 2>&1
  openssl req -new -key "$key_file" -out "$csr_file" -subj "/CN=$user/O=$group" >/dev/null 2>&1

  openssl x509 -req \
    -in "$csr_file" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$crt_file" \
    -days "$VALID_DAYS" >/dev/null 2>&1

  kubectl config set-cluster "$CLUSTER_NAME" \
    --server="$API_SERVER" \
    --certificate-authority="$CA_CRT" \
    --embed-certs=true \
    --kubeconfig="$kubeconfig_file" >/dev/null

  kubectl config set-credentials "$user" \
    --client-certificate="$crt_file" \
    --client-key="$key_file" \
    --embed-certs=true \
    --kubeconfig="$kubeconfig_file" >/dev/null

  kubectl config set-context "$user@$CLUSTER_NAME" \
    --cluster="$CLUSTER_NAME" \
    --user="$user" \
    --kubeconfig="$kubeconfig_file" >/dev/null

  kubectl config use-context "$user@$CLUSTER_NAME" --kubeconfig="$kubeconfig_file" >/dev/null

  rm -f "$csr_file"
  echo "Created user '$user' in group '$group': $kubeconfig_file"
done

echo "All users are created in $OUT_DIR"
