data "oci_core_image" "ubuntu_image" {
  image_id = "ocid1.image.oc1.iad.aaaaaaaayfc7vgsvgtmrlka74mdhyawbjmpcllntrowcuimb6nfxyqur734q"
}

data "template_file" "nomad_service" {
  template = <<EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

# When using Nomad with Consul it is not necessary to start Consul first. These
# lines start Consul before Nomad as an optimization to avoid Nomad logging
# that Consul is unavailable at startup.
#Wants=consul.service
#After=consul.service

[Service]

# Nomad server should be run as the nomad user. Nomad clients
# should be run as root
User=nomad
Group=nomad

ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
KillMode=process
KillSignal=SIGINT
LimitNOFILE=65536
LimitNPROC=infinity
Restart=on-failure
RestartSec=2

## Configure unit start rate limiting. Units which are started more than
## *burst* times within an *interval* time span are not permitted to start any
## more. Use `StartLimitIntervalSec` or `StartLimitInterval` (depending on
## systemd version) to configure the checking interval and `StartLimitBurst`
## to configure how many starts per interval are allowed. The values in the
## commented lines are defaults.

# StartLimitBurst = 5

## StartLimitIntervalSec is used for systemd versions >= 230
# StartLimitIntervalSec = 10s

## StartLimitInterval is used for systemd versions < 230
# StartLimitInterval = 10s

TasksMax=infinity
OOMScoreAdjust=-1000

[Install]
WantedBy=multi-user.target
EOF
}

data "template_file" "nomad_hcl" {
  template = <<EOF
datacenter = "dc1"
data_dir = "/opt/nomad"
EOF
}

data "template_file" "server_hcl" {
  template = <<EOF
server {
  enabled = true
  bootstrap_expect = 1
}
EOF
}

data "template_file" "client_hcl" {
  template = <<EOF
client {
  enabled = true
}

EOF
}


locals {
  nomad_server_initial_setup = <<EOF
#!/bin/bash
whoami
apt update
apt install firewalld software-properties-common iputils-ping vim unzip bash-completion -y
iptables-save > ~/iptables-rules
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=4646/tcp
firewall-cmd --zone=public --permanent --add-port=4647/tcp
firewall-cmd --zone=public --permanent --add-port=4648/tcp
firewall-cmd --reload
curl --silent --remote-name https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip
unzip nomad_${var.nomad_version}_linux_amd64.zip
chown root:root nomad
mv nomad /usr/local/bin/
nomad version
# nomad -autocomplete-install
# complete -C /usr/local/bin/nomad nomad
mkdir --parents /opt/nomad
echo -e "${data.template_file.nomad_service.rendered}" > /etc/systemd/system/nomad.service
mkdir --parents /etc/nomad.d
chmod 700 /etc/nomad.d
echo -e "${data.template_file.nomad_hcl.rendered}" > /etc/nomad.d/nomad.hcl
echo -e "${data.template_file.server_hcl.rendered}" > /etc/nomad.d/server.hcl
echo -e "${data.template_file.client_hcl.rendered}" >  /etc/nomad.d/client.hcl
systemctl enable nomad
systemctl start nomad
systemctl status nomad
EOF

  nomad_client_initial_setup = <<EOF
#!/bin/bash
whoami
apt update
apt install firewalld software-properties-common iputils-ping vim unzip bash-completion -y
iptables-save > ~/iptables-rules
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=4646/tcp
firewall-cmd --zone=public --permanent --add-port=4647/tcp
firewall-cmd --zone=public --permanent --add-port=4648/tcp
firewall-cmd --reload
curl --silent --remote-name https://releases.hashicorp.com/nomad/${var.nomad_version}/nomad_${var.nomad_version}_linux_amd64.zip
unzip nomad_${var.nomad_version}_linux_amd64.zip
chown root:root nomad
mv nomad /usr/local/bin/
nomad version
# nomad -autocomplete-install
# complete -C /usr/local/bin/nomad nomad
mkdir --parents /opt/nomad
echo -e "${data.template_file.nomad_service.rendered}" > /etc/systemd/system/nomad.service
mkdir --parents /etc/nomad.d
chmod 700 /etc/nomad.d
echo -e "${data.template_file.nomad_hcl.rendered}" > /etc/nomad.d/nomad.hcl
# echo -e "${data.template_file.server_hcl.rendered}" > /etc/nomad.d/server.hcl
echo -e "${data.template_file.client_hcl.rendered}" >  /etc/nomad.d/client.hcl
systemctl enable nomad
systemctl start nomad
systemctl status nomad
EOF
}
