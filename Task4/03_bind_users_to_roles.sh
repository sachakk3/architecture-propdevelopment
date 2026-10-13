#!/usr/bin/env bash
set -euo pipefail

# Creates namespace boundaries by org units and binds user groups to roles.

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: payments
---
apiVersion: v1
kind: Namespace
metadata:
  name: logistics
YAML

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grp-platform-admins-binding
subjects:
  - kind: Group
    name: grp-platform-admins
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: platform-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grp-security-auditors-secrets-binding
subjects:
  - kind: Group
    name: grp-security-auditors
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secrets-reader
  apiGroup: rbac.authorization.k8s.io
YAML

kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-viewers-binding
  namespace: payments
subjects:
  - kind: Group
    name: grp-payments-viewers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-engineers-binding
  namespace: payments
subjects:
  - kind: Group
    name: grp-payments-engineers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-configurator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: logistics-viewers-binding
  namespace: logistics
subjects:
  - kind: Group
    name: grp-logistics-viewers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-viewer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: logistics-engineers-binding
  namespace: logistics
subjects:
  - kind: Group
    name: grp-logistics-engineers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: namespace-configurator
  apiGroup: rbac.authorization.k8s.io
YAML

echo "Bindings are created/updated."
