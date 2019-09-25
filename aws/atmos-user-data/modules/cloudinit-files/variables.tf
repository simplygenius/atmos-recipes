variable "files" {
  type        = list(map(string))
  description = "A list of files (maps), each containing the keys path (required), content (required), owner (root:root), permissions (0644)"
}

variable "file_count" {
  description = "The file count"
}

