resource "oci_core_instance" "nomad_server" {
  availability_domain = var.oracle_availability_domain
  compartment_id      = var.oracle_compartment_id
  shape               = "VM.Standard.E2.1.Micro"

  defined_tags = {
    "Oracle-Tags.CreatedBy" = "oracleidentitycloudservice/${var.oracle_account_email}"
    # "Oracle-Tags.CreatedOn" = "2021-06-24T13:30:34.821Z"
  }

  display_name      = "Nomad Server"
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
    nsg_ids                = [oci_core_network_security_group.nomad_network_security_group.id]
    skip_source_dest_check = false
    subnet_id              = var.subnet_id
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
    source_id               = data.oci_core_image.ubuntu_image.image_id
    source_type             = "image"
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