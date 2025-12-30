output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = {
    public-ingress = concat(
      # aws_subnet.public-ingress-ipv6.*.id,
      aws_subnet.public-ingress.*.id,
      # aws_subnet.public-ingress-ipv4.*.id
    )
    public-egress = concat(
      # aws_subnet.public-egress-ipv6.*.id,
      aws_subnet.public-egress.*.id,
      # aws_subnet.public-egress-ipv4.*.id
    )
    private-egress = concat(
      # aws_subnet.private-egress-ipv6.*.id,
      aws_subnet.private-egress.*.id,
      # aws_subnet.private-egress-ipv4.*.id
    )
    private = concat(
      # aws_subnet.private-egress-ipv6.*.id,
      aws_subnet.private.*.id,
      # aws_subnet.private-egress-ipv4.*.id
    )
  }
}

output "route_tables" {
  value = {
    #public-ingress = aws_route_table.public-ingress.*.id
    public-egress = aws_route_table.public-egress.*.id
    private-egress = aws_route_table.private-egress.*.id
    private = aws_route_table.private.*.id
  }
}

# Used to add additional rules
output "network_acl" {
  value = {
    public-ingress = try(aws_network_acl.public-ingress[0].id, null)
    public-egress = try(aws_network_acl.public-egress[0].id, null)
    private-egress = try(aws_network_acl.private-egress.id, null)
    private = try(aws_network_acl.private.id, null)
  }
}

output "security_group" {
  value = {
    public-ingress = try(aws_security_group.public-ingress[0].id, null)
    public-egress = try(aws_security_group.public-egress[0].id, null)
    private-egress = try(aws_security_group.private-egress.id, null)
    private = try(aws_security_group.private.id, null)
  }
}

# For whitelisting on 3rd party services
output "public_ips" {
  value = aws_eip.nat.*.public_ip
}