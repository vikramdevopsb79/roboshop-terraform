module "network" {
  for_each = var.vpc
  source   = "./modules/network"

  cidr               = each.value["cidr"]
  subnets            = each.value["subnets"]
  availability_zones = each.value["availability_zones"]

  env = var.env
  peering_vpcs = each.value["peering_vpcs"]
}

module "db" {
  source = "./modules/ec2"
  for_each = var.db_servers
  env = var.env
  name = each.key
  ports = each.value["ports"]
  instance_type = each.value["instance_type"]

  zone_id       = var.zone_id
  vault_token   = var.vault_token
  bastion_nodes = var.bastion_nodes

  vpc_id = module.network["main"].vpc_id
  subnet_ids = module.network["main"].subnets["db"].subnets
}

module "app" {
  source = "./modules/ec2"
  for_each = var.app_servers
  depends_on = [module.db]
  env = var.env
  name = each.key
  ports = each.value["ports"]
  instance_type = each.value["instance_type"]

  zone_id       = var.zone_id
  vault_token   = var.vault_token
  bastion_nodes = var.bastion_nodes

  vpc_id = module.network["main"].vpc_id
  subnet_ids = module.network["main"].subnets["app"].subnets
}

module "web" {
  source = "./modules/ec2"
  for_each = var.web_servers
  depends_on = [module.app]
  env = var.env
  name = each.key
  ports = each.value["ports"]
  instance_type = each.value["instance_type"]

  zone_id       = var.zone_id
  vault_token   = var.vault_token
  bastion_nodes = var.bastion_nodes

  vpc_id = module.network["main"].vpc_id
  subnet_ids = module.network["main"].subnets["web"].subnets
}