resource "aws_vpc" "vpc" {
  cidr_block = var.cidr

  tags = {
    Name = "${var.env}-vpc"
  }

}

module "subnets" {
  source   = "./subnets"
  for_each = var.subnets

  name = each.key
  cidr = each.value["cidr"]

  availability_zones = var.availability_zones
  env                = var.env
  vpc_id          = aws_vpc.vpc.id
  ngw_ids        = aws_nat_gateway.ngw.*.id
  vpc_peering_ids = zipmap(local.peering_ids,local.peering_target_cidr )
}
resource "aws_eip" "ngw" {
  count  = length(var.availability_zones)
  domain = "vpc"
}
resource "aws_nat_gateway" "ngw" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.ngw.*.id[count.index]
  subnet_id     = module.subnets["public"].subnets[count.index]

  tags = {
    Name = "ngw-${split("-", var.availability_zones[count.index])[2]}"
  }
}
resource "aws_vpc_peering_connection" "peers" {
  for_each = var.peering_vpcs
  peer_vpc_id = each.value["id"]
  vpc_id      = aws_vpc.vpc.id
  auto_accept = true
  tags = {
    Name = "${each.key}-peers"
  }
}
# adding route to peering connection

resource "aws_route" "on-peer-side" {
  for_each = var.peering_vpcs
  route_table_id = each.value["route_table_id"]
  #our vpc cidr need to add in their route table and peering connection id
  destination_cidr_block = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peers[each.key].id
}
# in our routes also peering connection need to add
