resource "aws_subnet" "subnet" {
  count             = length(var.cidr)
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.name}-${var.env}-${split("-", var.availability_zones[count.index])[2]}"
  }
}

resource "aws_route_table" "route-table" {
  count             = length(var.cidr)
  vpc_id = var.vpc_id
  dynamic "route" {
    for_each = var.vpc_peering_ids
    content {
      cidr_block = route.value
      gateway_id = route.key
    }
  }
  tags = {
    Name = "${var.name}-${var.env}-${split("-", var.availability_zones[count.index])[2]}"
  }
  lifecycle {
    ignore_changes = [
      route
    ]
  }
}

resource "aws_route_table_association" "rt-association" {
  count = length(var.cidr)
  subnet_id = aws_subnet.subnet.*.id[count.index]
  route_table_id = aws_route_table.route-table.*.id[count.index]

}

resource "aws_internet_gateway" "igw" {
  count = var.name == "public" ? 1 : 0
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.env}-igw"

  }

}
resource "aws_route" "igw_route" {
  count = var.name == "public" ? length(var.cidr) : 0
  route_table_id = aws_route_table.route-table.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.*.id[0]
}
resource "aws_route" "ngw-route" {
  count                  = var.name != "public" ? length(var.cidr) : 0
  route_table_id         = aws_route_table.route-table.*.id[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.ngw_ids[count.index]
}

# I need peering connection for every route so i need added every route table i can go for dynamic blocking
# locals {
# peer_with_routes = { for i in aws_route_table.route-table.*.id: i => var.vpc_peering_ids}
#}
# resource "aws_route" "peer-route" {
#   for_each = var.vpc_peering_ids
#  for_each = local.peer_with_routes
#   route_table_id         = aws_route_table.route-table.*.id[count.index]
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = var.ngw_ids[count.index]
# }
