variable "availability_domain" {
  default = 1
  description = "If errors about 'shape not found', try 2 or 3.  See README for more information"
}

variable "ssh_public_key" {
  default = ""
}

# Variables for PetriR Script
variable "bucket_name" {
  default = "unifibackup"
  description = "Name of the Oracle Storage Bucket created previously"
}

variable "dns_name" {
  default = ""
  description = "DNS name for the public IP assigned."
}

variable "timezone" {
  default = ""
  description="Example America/Chicago"
}

variable "ddns_url" {
  default=""
  description = "URL to update Dynamic DNS entry such as http://freedns.afraid.org/dynamic/update.php?xxxdynamicTokenxxx"
}

# End of PetriR script variables

variable "project_name" {
  default = "unificontroller"
}

variable "instance_shape" {
  default = "VM.Standard.E2.1.Micro"
  description = "Shape Reference: https://docs.cloud.oracle.com/iaas/Content/Compute/References/computeshapes.htm"
}

variable "operating_system" {
  default = "Canonical Ubuntu"
  description = "Full name of OS without version number such as 'Canonical Ubuntu'"
}

variable "operating_system_version" {
  default = "18.04"
  description = "Version name of the specified OS, such as '18.04'"
}

resource "random_id" "unificontroller_id" {
  byte_length = 2
}

variable "region" {}
variable "compartment_ocid" {}
