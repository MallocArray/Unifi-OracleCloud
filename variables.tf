# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
variable "tenancy_ocid" {}

variable "region" {}

variable "compartment_ocid" {}

variable "availability_domain" {
  default = 1
}


variable "ssh_public_key" {
  default = ""
}

variable "project_name" {
  default = "unificontroller"
}

resource "random_id" "unificontroller_id" {
  byte_length = 2
}

# Variables for PetriR Script
# Work in progress

#variable "ddns-url" {default="update.url.com"}

#variable "timezone" {default="test-timezone"}

#variable "dns-name" {default="test.url.com"}

#variable "bucket" {default="bucket-name"}
