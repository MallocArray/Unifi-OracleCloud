# https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used

resource "oci_core_network_security_group" "unificontroller_network_security_group" {
    compartment_id = "${oci_identity_compartment.unificontroller_compartment.id}"
    vcn_id         = "${oci_core_vcn.unificontrollerVCN.id}"
    display_name   = "Unifi Controller Required Ports"
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_8080" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for device and application communication"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "8080"
            min = "8080"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_8443" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for controller GUI/API as seen in a web browser"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "8443"
            min = "8443"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_8880" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for HTTP portal redirection"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "8880"
            min = "8880"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_8843" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for HTTPS portal redirection"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "8843"
            min = "8843"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_6789" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for UniFi mobile speed test"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "6789"
            min = "6789"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_27117" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used for local-bound database communication"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "27117"
            min = "27117"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_80" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "6"
    description = "Port used HTTP portal redirection https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = "80"
            min = "80"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_3478" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Port used for STUN"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "3478"
            min = "3478"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_5514" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Port used for remote syslog capture"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "5514"
            min = "5514"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_5656" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Ports used by AP-EDU broadcasting"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "5699"
            min = "5656"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_10001" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Port used for device discovery"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "10001"
            min = "10001"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_1900" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Port used for 'Make controller discoverable on L2 network' in controller settings"
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "1900"
            min = "1900"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_123" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "INGRESS"
    protocol = "17"
    description = "Port used for NTP (date/time). Required for establishing secure communication with remote access servers."
    source   = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    udp_options {
        destination_port_range {
            max = "123"
            min = "123"
        }
    }
}
resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_3478_egress" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "EGRESS"
    protocol = "17"
    description = "Port used STUN"
    destination   = "0.0.0.0/0"
    udp_options {
        source_port_range {
            max = "3478"
            min = "3478"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_443_udp_egress" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "EGRESS"
    protocol = "17"
    description = "Port used for Remote Access service"
    destination   = "0.0.0.0/0"
    udp_options {
        source_port_range {
            max = "443"
            min = "443"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_443_tcp_egress" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "EGRESS"
    protocol = "6"
    description = "Port used for Remote Access service"
    destination   = "0.0.0.0/0"
    tcp_options {
        source_port_range {
            max = "443"
            min = "443"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_8883_tcp_egress" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "EGRESS"
    protocol = "6"
    description = "Port used for Remote Access service"
    destination   = "0.0.0.0/0"
    tcp_options {
        source_port_range {
            max = "8883"
            min = "8883"
        }
    }
}

resource "oci_core_network_security_group_security_rule" "unificontroller_network_security_group_security_rule_123_egress" {
    network_security_group_id = "${oci_core_network_security_group.unificontroller_network_security_group.id}"
    direction = "EGRESS"
    protocol = "17"
    description = "Port used for NTP (date/time). Required for establishing secure communication with remote access servers."
    destination   = "0.0.0.0/0"
    udp_options {
        source_port_range {
            max = "123"
            min = "123"
        }
    }
}
