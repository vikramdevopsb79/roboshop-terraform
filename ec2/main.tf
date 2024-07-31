resource "aws_security_group" "main" {
  name = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id = var.vpc_id
  tags = {
    Name ="${var.name}-${var.env}-sg"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_nodes
  }
  dynamic "ingress" {
    for_each = var.ports
    content {
      from_port = ingress.value["port"]
      to_port = ingress.value["port"]
      protocol = "TCP"
      cidr_blocks = ingress.value["cidr"]
      description = ingress.key
    }
  }
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.rhel9.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id = var.subnet_ids[0]
  tags = {
    Name = "${var.name}-${var.env}"
  }
}
resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}"
  type    = "A"
  ttl     = 10
  records = [aws_instance.main.private_ip]
}
resource "null_resource" "ansible" {
  depends_on = [aws_route53_record.record]
  provisioner "remote-exec" {
    connection {
      host     = aws_instance.main.private_ip
      user     = data.vault_generic_secret.ssh.data["username"]
      password = data.vault_generic_secret.ssh.data["password"]
    }

    inline = [
      "sudo set-prompt -skip-apply ${var.name}-${var.env}",
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost, -U https://github.com/vikramdevopsb79/roboshop-ansible -e env=${var.env} -e component=${var.name} -e vault_token=${var.vault_token} main.yml"
    ]
  }
}