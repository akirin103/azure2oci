data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_ocid
}

resource "oci_core_vcn" "this" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_ocid
  display_name   = "${var.system_name}-vcn"
}

resource "oci_core_subnet" "public" {
  cidr_block        = var.vcn_public_subnet_cidr_block
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.this.id
  display_name      = "${var.system_name}-public-subnet"
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]
}

resource "oci_core_subnet" "private" {
  cidr_block                 = var.vcn_private_subnet_cidr_block
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.system_name}-private-subnet"
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  ingress_security_rules {
    protocol    = "1"
    source      = oci_core_vcn.this.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = false
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 22
      min = 22
    }
  }
  vcn_id       = oci_core_vcn.this.id
  display_name = "${var.system_name}-public-sl"
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }
  ingress_security_rules {
    protocol    = "1"
    source      = oci_core_vcn.this.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = false
  }
  ingress_security_rules {
    protocol    = "6"
    source      = oci_core_vcn.this.cidr_block
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 22
      min = 22
    }
  }
  ingress_security_rules {
    protocol    = "1"
    source      = var.vnet_address_space[0]
    source_type = "CIDR_BLOCK"
    stateless   = false
  }
  ingress_security_rules {
    protocol    = "6"
    source      = var.vnet_address_space[0]
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      max = 22
      min = 22
    }
  }
  vcn_id       = oci_core_vcn.this.id
  display_name = "${var.system_name}-private-sl"
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
  vcn_id       = oci_core_vcn.this.id
  display_name = "${var.system_name}-public-rt"
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  route_rules {
    destination       = var.vnet_address_space[0]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.this.id
  }
  vcn_id       = oci_core_vcn.this.id
  display_name = "${var.system_name}-private-rt"
}

resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.system_name}-igw"
}

resource "oci_core_drg" "this" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.system_name}-drg"
}

resource "oci_core_drg_attachment" "this" {
  drg_id       = oci_core_drg.this.id
  vcn_id       = oci_core_vcn.this.id
  display_name = "${var.system_name}-drg-attach"
}

resource "oci_core_instance" "public" {
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[0], "name")
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  display_name        = "${var.system_name}-public-instance"
  create_vnic_details {
    subnet_id = oci_core_subnet.public.id
  }
  source_details {
    source_id   = var.instance_image_ocid
    source_type = "image"
  }
  metadata = {
    ssh_authorized_keys = file("${var.public_key_path}")
    user_data           = data.template_cloudinit_config.config.rendered
  }
}

resource "oci_core_instance" "private" {
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[0], "name")
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  display_name        = "${var.system_name}-private-instance"
  create_vnic_details {
    subnet_id        = oci_core_subnet.private.id
    assign_public_ip = false
  }
  source_details {
    source_id   = var.instance_image_ocid
    source_type = "image"
  }
  metadata = {
    ssh_authorized_keys = file("${var.public_key_path}")
    user_data           = data.template_cloudinit_config.config.rendered
  }
}

output "public_ip" {
  value = oci_core_instance.public.public_ip
}
