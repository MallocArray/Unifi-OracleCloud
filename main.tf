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

// https://docs.cloud.oracle.com/iaas/images/image/1ce54939-85b9-4dd2-9fc2-36bbe3b44613/
// Canonical-Ubuntu-18.04-2019.09.18-0
locals  {
  images = {
    ap-mumbai-1    =	"ocid1.image.oc1.ap-mumbai-1.aaaaaaaatimdje2ynbis3vhs7ifu6gc46enpkr4jqefeov7dhhywy3qdwuoa"
    ap-seoul-1     =	"ocid1.image.oc1.ap-seoul-1.aaaaaaaal4ilrxr2urapzigeemrodzitumfwg6f4mjdwbnjv2dl7d3ufmpla"
    ap-sydney-1    =	"ocid1.image.oc1.ap-sydney-1.aaaaaaaapqr3lht5gxmvx33c3srdwjihxw7xlzjx53zz6z6aiy6iddbyhojq"
    ap-tokyo-1     =	"ocid1.image.oc1.ap-tokyo-1.aaaaaaaas7mayq334jx6wwo5mvsacsrhqltqu4oexeygb6sx24zvgjy63haq"
    ca-toronto-1   =	"ocid1.image.oc1.ca-toronto-1.aaaaaaaay4q4rliuwpqdd3zy33wb42k5g3pbgrrtrwfrqzgazbu4rma5jtza"
    eu-frankfurt-1 =	"ocid1.image.oc1.eu-frankfurt-1.aaaaaaaayvqumqej62xz6rm7q4o2jdpjgvbn3yxa6zzybmmqop2ueksachzq"
    eu-zurich-1    =	"ocid1.image.oc1.eu-zurich-1.aaaaaaaax3upi7v7o5xqekromo5c3awp65rfzv2kbqkjupddgusc72l4ospa"
    sa-saopaulo-1  =	"ocid1.image.oc1.sa-saopaulo-1.aaaaaaaarna7nv5emly2akcd2wqsm2zgkqmrmc5w5lctwjwn5232annhiaca"
    uk-london-1    =	"ocid1.image.oc1.uk-london-1.aaaaaaaaxkewl2rhku6s72n6b76ng7g6tzuencdgle7iemmll53ywzjz6mea"
    us-ashburn-1   =	"ocid1.image.oc1.iad.aaaaaaaap7b6qyutg6lphvxjqspbielyxavfxfynaqtdxudr3feb62nsw6jq"
    us-langley-1   =	"ocid1.image.oc2.us-langley-1.aaaaaaaaa6hxzk7abxnlzn6ivunvw6vthoz4hc7wdcwoyifcjroi5zgluxwa"
    us-luke-1      =	"ocid1.image.oc2.us-luke-1.aaaaaaaalp25othpiznso7al4za2sw5oc3lo65y72bh2dv34depjsz4wdd5q"
    us-phoenix-1   =	"ocid1.image.oc1.phx.aaaaaaaa5rdkagpkgrn33wu5cz63unpwcsvka6ofen7nqsan4safhuufwb5q"
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
