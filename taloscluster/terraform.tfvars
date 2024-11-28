cluster_name = "talos01"

control_plane = {
  instance_type = "m6a.large"
}

worker_groups = [ {
  name = "wg0"
  num_instances = 3
  instance_type = "i4i.xlarge"
  config_patch_files = [ "openebs-i4i.yaml" ]
} ]

extra_tags = {
  "Owner" = "Tutorials and Workshops"
  "Repository" = "https://github.com/wagov-dtt/tutorials-and-workshops"
}