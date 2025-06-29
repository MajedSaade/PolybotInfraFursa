#!/bin/bash
set -e

echo "[INFO] Starting Kubernetes control plane setup..."

# Exit if already initialized
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "[INFO] Kubernetes is already initialized. Skipping."
    exit 0
fi

# Get private IP dynamically from AWS metadata
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "[INFO] Private IP: $PRIVATE_IP"

# Initialize Kubernetes control plane
echo "[INFO] Running kubeadm init..."
kubeadm init \
  --apiserver-advertise-address="$PRIVATE_IP" \
  --pod-network-cidr=192.168.0.0/16

# Set up kubectl config for root
mkdir -p /root/.kube
cp -f /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config

# Wait for default user (UID 1000) and home directory to be ready
for i in {1..30}; do
  DEFAULT_USER=$(getent passwd 1000 | cut -d: -f1)
  USER_HOME=$(getent passwd 1000 | cut -d: -f6)
  if [ -n "$DEFAULT_USER" ] && [ -d "$USER_HOME" ]; then
    echo "[INFO] Found user '$DEFAULT_USER' with home '$USER_HOME'"
    break
  fi
  echo "[INFO] Waiting for user with UID 1000 to be ready..."
  sleep 1
done

# Set up kubectl config for the default non-root user (e.g. ubuntu)
if [ -n "$DEFAULT_USER" ] && [ -d "$USER_HOME" ]; then
  echo "[INFO] Setting up kubectl config for $DEFAULT_USER..."
  mkdir -p "$USER_HOME/.kube"
  cp -f /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
  chown "$DEFAULT_USER:$DEFAULT_USER" "$USER_HOME/.kube/config"
  sed -i '/export KUBECONFIG/d' "$USER_HOME/.bashrc"
fi

# Apply Calico CNI if not already applied
echo "[INFO] Installing Calico CNI (if needed)..."
if ! kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -n kube-system 2>/dev/null | grep -q calico; then
  kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
fi

# Output the worker join command
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "[INFO] Worker join command:"
echo "$JOIN_CMD"

# Upload the join command to SSM Parameter Store
aws ssm put-parameter \
  --name "/k8s/worker/join-command" \
  --type "SecureString" \
  --value "$JOIN_CMD" \
  --overwrite \
  --region us-west-2

# ✅ Create dev and prod namespaces inline
echo "[INFO] Creating dev and prod namespaces directly..."
cat <<EOF | kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: dev
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
EOF

echo "[INFO] Control plane initialization complete."
