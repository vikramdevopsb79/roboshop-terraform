resource "aws_instance" "instance" {
  count = length(var.components)
  ami           = data.aws_ami.rhel9.id
  instance_type = "t3.small"
  security_groups = [aws_security_group.sg.*.id[count.index]]
  tags = {
    Name = "${var.components[count.index]}-${var.env}"
  }
}
resource "aws_security_group" "sg" {
  count = length(var.components)
  name = "${var.components[count.index]}-${var.env}"
  description = "${var.components[count.index]}-${var.env}"
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  tags = {
    Name = "${var.components[count.index]}-${var.env}"
  }
}
resource "aws_route53_zone" "record" {
  count = length(var.components)
  zone_id = aws_route53_zone.record.zone_id
  name    = "${var.components[count.index]}-${var.env}"
  type    = "A"
  ttl     = "10"
  records = [aws_instance.instance.*.private_ip[count.index]]
}
resource "null_resource" "prompt" {
  count =  length(var.components)
  connection {
    type     = "ssh"
    user     = data.vault_generic_secret.ssh.data["username"]
    password = data.vault_generic_secret.ssh.data["password"]
    host     = aws_instance.instance.*.private_ip[count.index]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo set-prompt -skip-apply ${var.components[count.index]}-${var.env}",
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost, -U https://github.com/vikramdevopsb79/roboshop-ansible -e env=${var.env} -e component=${var.components[count.index]} -e vault_token=${var.vault_token} main.yml"
    ]
  }

}