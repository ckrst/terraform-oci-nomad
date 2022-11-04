variable "oracle_compartment_id" {
  description = "The OCID of the compartment."
}

variable "oracle_availability_domain" {
  description = "The OCID of the availability domain."
}

variable "oracle_account_email" {
  description = "The email of the Oracle Cloud Infrastructure account."
}

variable "vcn_id" {
  description = "The OCID for the VCN."
}

variable "subnet_id" {
  description = "Subnet ID"
}

variable "public_key" {
  description = "Public key"
}

variable "nomad_version" {
  default = "1.1.0"
}

variable "api_allowed_ip" {
  default = "0.0.0.0/0"
}

variable "allow_tcp_private_ports" {
  type        = set(string)
  description = "Allow tcp ports private"
}
variable "allow_udp_private_ports" {
  type        = set(string)
  description = "Allow udp ports private"
}

variable "allow_tcp_public_ports" {
  type        = set(string)
  description = "Allow tcp ports public"
}
variable "allow_udp_public_ports" {
  type        = set(string)
  description = "Allow udp ports public"
}