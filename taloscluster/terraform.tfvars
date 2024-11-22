cluster_name = "talos01"

control_plane = {
  instance_type = "m6a.large"
}

worker_groups = [ {
  name = "wg0"
  num_instances = 3
  instance_type = "i4i.xlarge"
} ]

extra_tags = {
  "Owner" = "Tutorials and Workshops"
  "Repository" = "https://github.com/wagov-dtt/tutorials-and-workshops"
}