# For Kubernetes Master Node 
sudo hostnamectl set-hostname K8s-Master

sudo su
swapoff -a; sed -i '/swap/d' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# In case of error
# sudo apt install etables -y
# sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# To check if everything ok 
# lsmod |grep overlay
# lsmod |grep br_netfilter

sudo apt update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg


apt install docker.io -y
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd.service

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key |gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" |tee /etc/apt/sources.list.d/kubernetes.list 
apt update 
sudo apt-get install –y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
systemctl restart kubelet.service
systemctl enable kubelet.service

kubeadm init --apiserver-advertise-address=master.ip --pod-network-cidr=10.244.0.0/16
exit
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Kubernetes networking distribution : Weave pulled from github official weave repos 
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

##Adding nodes exporter to send metrics to prometheus - grafana server
# Create prometheus user
sudo useradd \
--system \
--no-create-home \
--shell /bin/false prometheus

#Install nodes exporter 
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

#Create the systemd configuration file for node exporter.

sudo vim /etc/systemd/system/node_exporter.service

#Paste
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
 - collector.logind
[Install]
WantedBy=multi-user.target

sudo systemctl restart node_exporter
sudo systemctl enable node_exporter
systemctl status node_exporter.service
