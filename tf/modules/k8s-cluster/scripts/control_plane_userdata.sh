#!/bin/bash
set -e

# === System Prep for Kubernetes ===
KUBERNETES_VERSION="v1.32"

# Update packages
sudo apt-get update
sudo apt-get install -y jq unzip ebtables ethtool software-properties-common apt-transport-https ca-certificates curl gpg

# Install awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Enable IP forwarding
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Add Kubernetes and CRI-O repositories
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update
sudo apt-get install -y cri-o kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start CRI-O and kubelet
sudo systemctl enable --now crio.service
sudo systemctl enable --now kubelet

# Disable swap
swapoff -a
(crontab -l ; echo "@reboot /sbin/swapoff -a") | crontab -

# === Download and Run Kubeadm Init Script from S3 ===
if [ ! -f /etc/kubernetes/admin.conf ]; then
  aws s3 cp s3://majed-tf-backend/scripts/kubeadm-init.sh /tmp/kubeadm-init.sh
  chmod +x /tmp/kubeadm-init.sh
  # Fetch the instance's private IP
  CONTROL_PLANE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
  sudo /tmp/kubeadm-init.sh "$CONTROL_PLANE_IP"
else
  echo "Kubernetes already initialized. Skipping kubeadm init."
fi

