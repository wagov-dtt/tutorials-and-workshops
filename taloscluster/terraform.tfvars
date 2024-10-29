cluster_name = "talos01"

control_plane = {
  instance_type = "m6a.large"
}

worker_groups = [ {
  name = "wg0"
  instance_type = "i4i.large"
} ]

extra_tags = {
  "Owner" = "Tutorials and Workshops"
  "Repository" = "https://github.com/wagov-dtt/tutorials-and-workshops"
}