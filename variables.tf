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