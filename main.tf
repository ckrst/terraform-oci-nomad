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
nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad
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
}

# oracle instances
resource "oci_core_instance" "nomad_server" {
  availability_domain = var.oracle_availability_domain
  compartment_id = var.oracle_compartment_id
  shape = "VM.Standard.E2.1.Micro"

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "oracleidentitycloudservice/${var.oracle_account_email}"
    # "Oracle-Tags.CreatedOn" = "2021-06-24T13:30:34.821Z"
  }

  display_name = "Nomad Server"
  extended_metadata = {}
  freeform_tags     = {}
  metadata = {
    ssh_authorized_keys = var.public_key
    user_data           = base64encode(local.nomad_server_initial_setup)
  }

  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled   = false
    is_monitoring_disabled   = false

    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
  }

  availability_config {
    is_live_migration_preferred = false
    recovery_action             = "RESTORE_INSTANCE"
  }

  create_vnic_details {
    assign_public_ip = true
    defined_tags = {
      "Oracle-Tags.CreatedBy" = "oracleidentitycloudservice/${var.oracle_account_email}"
      # "Oracle-Tags.CreatedOn" = "2021-06-24T13:30:35.220Z"
    }
    display_name           = "Nomad Server"
    freeform_tags          = {}
    hostname_label         = "nomad-server"
    nsg_ids = [ oci_core_network_security_group.nomad_network_security_group.id ]
    skip_source_dest_check = false
    subnet_id = var.subnet_id
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = false
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }

  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }

  source_details {
    boot_volume_size_in_gbs = "50"
    source_id = data.oci_core_image.ubuntu_image.image_id
    source_type = "image"
  }
  
  lifecycle {
    ignore_changes = [
      defined_tags,
      create_vnic_details,
      launch_options,
      metadata
    ]
  }
  
}