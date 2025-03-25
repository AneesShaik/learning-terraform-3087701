module "qa" {
  source = "../module/blog"

  environment = {
    name="qa-huma"
    network_prefix="10.1"

  }
  asg_min =1
  asg_max=1
}