# data "template_file" "unifi-init" {
#   template = "${file("./cloud-init/unifi-init.yaml")}"
# }

data "template_file" "unifi-petrir" {
  template = "${file("./cloud-init/startup.sh")}"
  # These don't mean anything, but they have to be defined to not cause errors
  vars = {
    bucket = "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.unifi_backup_preauthenticated_request.access_uri}"
    ddns = "${var.ddns_url}"
    tz="${var.timezone}"
    MONGOLOG=""
    Status=""
    httpd=""
    f2b=""
    dnsname=""
    caroot=""
    p12=""
    extIP=""
    dnsIP=""
  }
}

# data "template_cloudinit_config" "config" {
#   # https://ash.berlintaylor.com/writings/2017/08/reusable-terraform-modules-extending-userdata/
#   # https://www.terraform.io/docs/providers/template/d/cloudinit_config.html
#   part {
#     content_type = "text/cloud-config"
#     content = "${data.template_file.unifi-init.rendered}"
#   }
#   part {
#     filename="petrir-modified.sh"
#     content_type = "text/x-shellscript"
#     content = "${data.template_file.unifi-petrir.rendered}"
#   }
# }


resource "oci_identity_compartment" "unificontroller_compartment" {
    compartment_id = "${var.compartment_ocid}"
    description = "Unifi Controller Compartment"
    name = "${var.project_name}"
}

resource "oci_core_instance" "unificontroller_instance" {
  availability_domain = "${data.oci_identity_availability_domain.unificontroller-AD.name}"
  compartment_id      = "${oci_identity_compartment.unificontroller_compartment.id}"
  shape               = "${var.instance_shape}"
  display_name        = "${var.project_name}-${random_id.unificontroller_id.dec}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.unificontrollerSubnet.id}"
    nsg_ids          = ["${oci_core_network_security_group.unificontroller_network_security_group.id}"]
  }

  source_details {
    source_type = "image"
    #source_id   = "${local.images[var.region]}"
    source_id   = "${lookup(data.oci_core_images.supported_shape_images.images[0], "id")}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    #user_data           = "${base64encode(data.template_file.unifi-init.rendered)}"
    user_data           = "${base64encode(data.template_file.unifi-petrir.rendered)}"
    ddns-url            = "${var.ddns_url}"
    timezone            = "${var.timezone}"
    dns-name            = "${var.dns_name}"
    bucket              = "https://objectstorage.${var.region}.oraclecloud.com${oci_objectstorage_preauthrequest.unifi_backup_preauthenticated_request.access_uri}"
  }

}


data "oci_identity_availability_domain" "unificontroller-AD" {
    #Required
    compartment_id = "${var.compartment_ocid}"
    #Optional
    ad_number = "${var.availability_domain}"
}


# Gets a list of images within a tenancy with the specified criteria
data "oci_core_images" "supported_shape_images" {
  compartment_id = "${var.compartment_ocid}"

  # Uncomment below to filter images that support a specific instance shape
  #shape                    = "VM.Standard.E2.1.Micro"
  shape                     = "${var.instance_shape}"

  # Uncomment below to filter images that are a specific OS
  operating_system         = "${var.operating_system}"

  # Uncomment below to filter images that are a specific OS version
  operating_system_version = "${var.operating_system_version}"

  # Uncomment below to sort images by creation time
  sort_by                 = "TIMECREATED"
  # Default sort order for TIMECREATED is descending (DESC)
  #sort_order              = "ASC"

  state                   = "AVAILABLE"

  # Uncomment below to sort images by display name, display name sort order is case-sensitive
  #sort_by                 = "DISPLAYNAME"
  # Default sort order for DISPLAYNAME is ascending (ASC)
  #sort_order              = "DESC"
}

# Hints to getting the list of available images to always get the most recent
# https://github.com/terraform-providers/terraform-provider-oci/blob/master/examples/compute/image/image.tf

# https://www.exitas.be/blog/assigning-reserved-public-ips-to-guests-with-oracle-cloud-and-terraform/
# Great guide to creating and assigning a Reserved public IP but destroys it when destroying everything else

#data "oci_core_private_ips" "unificontroller_private_ips" {
#  ip_address = oci_core_instance.unificontroller-instance.private_ip
#  subnet_id  = oci_core_subnet.unificontrollerSubnet.id
#}

#resource "oci_core_public_ip" "unificontroller_public_ip" {
#  compartment_id = "${oci_identity_compartment.unificontroller_compartment.id}"
#  display_name   = "Unifi Controller Public IP"
#  lifetime       = "RESERVED"
#  private_ip_id  = data.oci_core_private_ips.unificontroller_private_ips.private_ips[0]["id"]
#}
