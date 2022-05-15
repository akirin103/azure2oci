# Common
variable "system_name" {
  default = "azure2oci"
}
# Microsoft Azure
variable "location" {
  default = "japaneast"
}

variable "vnet_address_space" {
  default = ["10.20.0.0/16"]
}

variable "vnet_subnet_names" {
  default = ["public", "private", "GatewaySubnet"]
}

variable "vnet_subnet_prefixes" {
  default = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
}

variable "virtual_machine_size" {
  default = "Standard_B1ls"
}

variable "storage_account_type" {
  default = "Standard_LRS"
}
# Oracle Cloud Inflastructure
variable "vcn_cidr_block" {
  default = "10.10.0.0/16"
}

variable "vcn_public_subnet_cidr_block" {
  default = "10.10.0.0/24"
}

variable "vcn_private_subnet_cidr_block" {
  default = "10.10.1.0/24"
}

variable "vcn_display_name" {
  default = "oci-vcn"
}

variable "instance_shape" {
  default = "VM.Standard.E2.1.Micro"
}

variable "instance_image_ocid" {
  # See https://docs.us-phoenix-1.oraclecloud.com/images/
  default = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaaiqnzylthf6siyhwrnwu7fzci2clbp4rpdtuok6byikb727nklc5q"
}

variable "public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}
