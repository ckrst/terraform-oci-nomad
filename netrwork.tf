resource "oci_core_network_security_group" "nomad_network_security_group" {
  compartment_id = var.oracle_compartment_id
  vcn_id         = var.vcn_id
  display_name   = "Nomad Security Group"
}

resource "oci_core_network_security_group_security_rule" "nomad_network_security_group_security_rule_web" {
  network_security_group_id = oci_core_network_security_group.nomad_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" #TCP
  description               = "Allow web port"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  # stateless = false
  tcp_options {
    destination_port_range {
      min = "80"
      max = "80"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "nomad_network_security_group_security_rule_ingress" {
  network_security_group_id = oci_core_network_security_group.nomad_network_security_group.id
  direction                 = "INGRESS"
  protocol                  = "6" #TCP
  description               = "Allow nomad ports"
  source                    = var.api_allowed_ip
  source_type               = "CIDR_BLOCK"
  # stateless = false
  tcp_options {
    destination_port_range {
      min = "4646"
      max = "4648"
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nomad_network_security_group_security_rule_egress" {
  network_security_group_id = oci_core_network_security_group.nomad_network_security_group.id
  direction                 = "EGRESS"
  protocol                  = "all"
  description               = "Allow all tcp ports"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"

}