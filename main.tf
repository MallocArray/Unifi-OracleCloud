data "template_file" "unifi-init" {
  template = "${file("./cloud-init/unifi-init.yaml")}"
}

resource "oci_identity_compartment" "unificontroller_compartment" {
    compartment_id = "${var.compartment_ocid}"
    description = "Unifi Controller Compartment"
    name = "${var.project_name}"
}

resource "oci_core_instance" "unificontroller-instance" {
  availability_domain = "${data.oci_identity_availability_domain.unificontroller-AD.name}"
  compartment_id      = "${oci_identity_compartment.unificontroller_compartment.id}"
  shape               = "${local.instance_shape}"
  display_name        = "${var.project_name}-${random_id.unificontroller_id.dec}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.unificontrollerSubnet.id}"
    nsg_ids          = ["${oci_core_network_security_group.unificontroller_network_security_group.id}"]
  }

  source_details {
    source_type = "image"
    source_id   = "${local.images[var.region]}"
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(data.template_file.unifi-init.rendered)}"
    #ddns-url            = "${var.ddns-url}"
    #timezone            = "${var.timezone}"
    #dns-name            = "${var.dns-name}"
    #bucket              = "${var.bucket}"
  }

}

// https://docs.cloud.oracle.com/iaas/images/image/959c3bab-acd8-4d1c-9183-0b105fdd4675/
// Canonical-Ubuntu-16.04-2019.08.14-0
locals  {
  images = {
    ap-mumbai-1    =	"ocid1.image.oc1.ap-mumbai-1.aaaaaaaazbg4glzqf5ca7lufx72pxh5z3mjur6rju6vg4dncgvfkxn4hsm2a"
    ap-seoul-1     =	"ocid1.image.oc1.ap-seoul-1.aaaaaaaavj2xqqyoe7fgloayt2upupkvtqrd5cld7gpbng2iogwd4tzzylja"
    ap-sydney-1    =	"ocid1.image.oc1.ap-sydney-1.aaaaaaaanqcaertfztukqitv7nyfoa5tfkc7ossq7mbrf6eovi7cv5geva7q"
    ap-tokyo-1     =	"ocid1.image.oc1.ap-tokyo-1.aaaaaaaavafdy6turyejyoteynggaogbvmdcy2zwl5ukgy3mww6ohbmrgs7q"
    ca-toronto-1   =	"ocid1.image.oc1.ca-toronto-1.aaaaaaaasemjn4uake6p54v6pyuq7ylc44nmm3gn24d6oyntjw7b2d7wa45q"
    eu-frankfurt-1 =	"ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaguuudmn7kx7wcy3knxqe663bpbz6rhc42zxqt6wdqvght6az3tpq"
    eu-zurich-1    =	"ocid1.image.oc1.eu-zurich-1.aaaaaaaauajkxxy66ykihw2pejzngjdb5msbynm4gzsbmqus3itrn5wqzshq"
    sa-saopaulo-1  =	"ocid1.image.oc1.sa-saopaulo-1.aaaaaaaawmbc6cmmpnc7q4yknhbx2c5ejdzgmm43ee4qs2bfivyjppprxdpa"
    uk-london-1    =	"ocid1.image.oc1.uk-london-1.aaaaaaaamjkgj6vehzwz666pwzmadktjv357nwspvvyipmlvhrezsfzucslq"
    us-ashburn-1   =	"ocid1.image.oc1.iad.aaaaaaaaazvqm5qnt4c7dbjn5tztubhbrsl7x34x2vxsvtns5bf63y6s2btq"
    us-langley-1   =	"ocid1.image.oc2.us-langley-1.aaaaaaaajrf4fkoyx4wdi2mkla4um5kovrhscqqk5bhzujp73xl5mffeybfq"
    us-luke-1      =	"ocid1.image.oc2.us-luke-1.aaaaaaaa73qnm5jktrwmkutf6iaigib4msieymk2s5r5iweq5yvqublgcx5q"
    us-phoenix-1   =	"ocid1.image.oc1.phx.aaaaaaaa73k7r3vhby4gn3cfm62hiaacyezyef3gth6nh752fsoct6hnys2q"
  }

  instance_shape = "VM.Standard.E2.1.Micro"

  availability_domain = 1

  num_nodes = 1

}

data "oci_identity_availability_domain" "unificontroller-AD" {
    #Required
    compartment_id = "${var.compartment_ocid}"
    #Optional
    ad_number = "${var.availability_domain}"
}

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
