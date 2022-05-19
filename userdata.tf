// Used for User Data for VMs in Azure and OCI
data "template_file" "script" {
  template = file("${path.module}/cloud-init.yml")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.script.rendered
  }
}
