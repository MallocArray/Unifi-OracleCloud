resource "oci_core_vcn" "unificontrollerVCN" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = "${oci_identity_compartment.unificontroller_compartment.id}"
  display_name   = "${var.project_name}-${random_id.unificontroller_id.dec}"
  dns_label      = "${var.project_name}"
  is_ipv6enabled = "false"
}

resource "oci_core_internet_gateway" "unificontrollerIG" {
  compartment_id = "${oci_identity_compartment.unificontroller_compartment.id}"
  display_name   = "${var.project_name}-IG-${random_id.unificontroller_id.dec}"
  vcn_id         = "${oci_core_vcn.unificontrollerVCN.id}"
}

resource "oci_core_route_table" "unificontrollerRT" {
  compartment_id = "${oci_identity_compartment.unificontroller_compartment.id}"
  vcn_id         = "${oci_core_vcn.unificontrollerVCN.id}"
  display_name   = "${var.project_name}-RT-${random_id.unificontroller_id.dec}"
    route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.unificontrollerIG.id}"
    }
}

resource "oci_core_subnet" "unificontrollerSubnet" {
  cidr_block                 = "10.0.100.0/24"
  compartment_id             = "${oci_identity_compartment.unificontroller_compartment.id}"
  vcn_id                     = "${oci_core_vcn.unificontrollerVCN.id}"
  display_name               = "${var.project_name}-${random_id.unificontroller_id.dec}"
  route_table_id             = "${oci_core_route_table.unificontrollerRT.id}"
}
