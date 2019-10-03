output "instance_public_ip" {
  value = "${oci_core_instance.unificontroller-instance.public_ip}"
  }

output "controller_public_url" {
  value = "${format("https://%s:8443", oci_core_instance.unificontroller-instance.public_ip)}"
}

output "comments" {
  value = "The controller should become available in aproximately 15-20 minutes, once updates and installation have completed"
}
