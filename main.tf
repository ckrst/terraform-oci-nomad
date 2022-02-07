data "oci_core_image" "ubuntu_image" {
  image_id = "ocid1.image.oc1.iad.aaaaaaaayfc7vgsvgtmrlka74mdhyawbjmpcllntrowcuimb6nfxyqur734q"
}

locals {
  nomad_server_initial_setup = <<EOF
#!/bin/bash
whoami
apt update
apt install firewalld -y
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
chown root:root nomad.service
mv nomad.service /etc/systemd/system/nomad.service
mkdir --parents /etc/nomad.d
chmod 700 /etc/nomad.d
chown root:root nomad.hcl
mv /home/ubuntu/nomad.hcl /etc/nomad.d/
chown root:root server.hcl
mv /home/ubuntu/server.hcl /etc/nomad.d/
chown root:root client.hcl
mv /home/ubuntu/client.hcl /etc/nomad.d/

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