output "nomad_server" {
  value = oci_core_instance.nomad_server.public_ip
}

output "nomad_server_private_id" {
  value = oci_core_instance.nomad_server.private_ip
}