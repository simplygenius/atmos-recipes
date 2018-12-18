data "template_file" "cloudinit-file-entry" {
  count = "${var.file_count}"
  // NOTE: Ensures generated yml is indented correctly by replacing newine with newline+spaces
  template = "${file("${path.module}/file_entry.tmpl.yml")}"

  vars {
    path = "${lookup(var.files[count.index], "path")}"
    content = "${lookup(var.files[count.index], "content")}"
    owner = "${lookup(var.files[count.index], "owner", "root:root")}"
    permissions = "${lookup(var.files[count.index], "permissions", "0644")}"
  }
}

data "template_file" "cloudinit-write-files-config" {
  // Since bash can use ${} for var references, we need to use a template to
  // ensure they don't get interpolated by terraform
  template = <<EOF
write_files:
$${replace(files, "*&^%", "\n")}

EOF
  vars {
    // Use an unlikely delimiter to work around lack of lists in template vars
    files = "${join("*&^%", data.template_file.cloudinit-file-entry.*.rendered)}"
  }
}
