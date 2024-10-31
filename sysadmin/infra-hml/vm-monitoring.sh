sudo useradd \
 - system \
 - no-create-home \
 - shell /bin/false prometheus
 
wget https://github.com/prometheus/prometheus/releases/download/v2.49.0-rc.1/prometheus-2.49.0-rc.1.linux-amd64.tar.gz
tar -xvf prometheus-2.49.0-rc.1.linux-amd64.tar.gz


sudo mkdir -p /data /etc/prometheus
cd prometheus-2.49.0-rc.1.linux-amd64/

sudo mv prometheus promtool /usr/local/bin/

sudo mv consoles console_libraries/ prometheus.yml /etc/prometheus/

sudo chown -R prometheus:prometheus /etc/prometheus/ /data/

prometheus --version

sudo vim /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
 - config.file=/etc/prometheus/prometheus.yml \
 - storage.tsdb.path=/data \
 - web.console.templates=/etc/prometheus/consoles \
 - web.console.libraries=/etc/prometheus/console_libraries \
 - web.listen-address=0.0.0.0:9090 \
 - web.enable-lifecycle
[Install]
WantedBy=multi-user.target


sudo systemctl enable prometheus.service
sudo systemctl start prometheus.service
systemctl status prometheus.service


sudo useradd \
 - system \
 - no-create-home \
 - shell /bin/false node_exporter

 wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
node_exporter --version


sudo vim /etc/systemd/system/node_exporter.service
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


sudo systemctl enable node_exporter
sudo systemctl enable node_exporter
systemctl status node_exporter.service

sudo vim /etc/prometheus/prometheus.yml
##add
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]



promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload

sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg - dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update

sudo apt-get install grafana

sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server.service
sudo systemctl status grafana-server.service

sudo vim /etc/prometheus/prometheus.yml
##add
- job_name: "jenkins"
    static_configs:
      - targets: ["<jenkins-server-public-ip>:8080"]


      
promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload


sudo vim /etc/prometheus/prometheus.yml
- job_name: "node_export_K8s_master"
    static_configs:
      - targets: ["<jenkins-server-public-ip>:9100"]

promtool check config /etc/prometheus/prometheus.yml
curl -X POST http://localhost:9090/-/reload
