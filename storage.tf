data "oci_objectstorage_namespace" "objectstorage_namespace" {
    #Optional
    compartment_id = "${var.compartment_ocid}"
}

resource "oci_objectstorage_preauthrequest" "unifi_backup_preauthenticated_request" {
    #Required
    access_type = "AnyObjectReadWrite"
    bucket = "${var.bucket_name}"
    name = "Unifi_Backup"
    namespace = "${data.oci_objectstorage_namespace.objectstorage_namespace.namespace}"
    time_expires = "2050-12-31T00:00:00Z"

}
