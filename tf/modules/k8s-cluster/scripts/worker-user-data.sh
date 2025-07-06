#!/bin/bash
set -e

exec > >(tee /var/log/worker-init.log | logger -t user-data -s) 2>&1

echo "[worker-user-data] Starting worker setup"

# Enable IP forwarding
echo "Enabling IP forwarding"
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/k8s.conf
sysctl --system

# Install dependencies and Kubernetes components
if ! command -v kubelet &> /dev/null; then
  echo "Installing Kubernetes and CRI-O..."

  apt-get update
  apt-get install -y curl jq ebtables ethtool unzip runc

  if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
  fi

  # Add Kubernetes repo
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

  # Add CRI-O repo
  curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" > /etc/apt/sources.list.d/cri-o.list

  apt-get update
  apt-get install -y kubelet kubeadm kubectl cri-o
  apt-mark hold kubelet kubeadm kubectl
fi

echo " Starting CRI-O..."
systemctl enable crio
systemctl start crio

# Join loop
echo "Waiting for join command from SSM..."
while true; do
  if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "Already joined the cluster."
    break
  fi

  JOIN_CMD=$(aws ssm get-parameter \
    --name "/k8s/worker/join-command" \
    --with-decryption \
    --region us-west-2 \
    --query "Parameter.Value" \
    --output text 2>/dev/null || true)

  if [[ "$JOIN_CMD" == kubeadm* ]]; then
    if [[ "$JOIN_CMD" != *"--cri-socket="* ]]; then
      JOIN_CMD="$JOIN_CMD --cri-socket=unix:///var/run/crio/crio.sock"
    fi

    echo "Attempting to join the cluster..."
    $JOIN_CMD && echo "Join successful!" && break || echo " Join failed. Retrying..."
  else
    echo "⏳ Join command not available yet. Retrying..."
  fi

  sleep 15
done
