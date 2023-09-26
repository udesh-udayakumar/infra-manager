module "infra-manager" {
  source = "./module"

  project_name = var.project_name
  vpc_name     = var.vpc_name
  region       = var.region
  zone         = var.zone
  subnet       = var.subnet
  vm_name      = var.vm_name
  machine_type = var.machine_type
}