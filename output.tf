output "id" {
  value = aws_vpc.main.id
}

# For LB
output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}
# For NAT
output "public_egress_subnet_ids" {
  value = aws_subnet.public-egress.*.id
}

# For bastion, ECS,etc
output "private_egress_subnet_ids" {
  value = aws_subnet.private-egress.*.id
}
# For RDS, etc
output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

# For VPC endpoints
//output "private_route_table_ids" {
//  value = concat(
//    aws_route_table.private.*.id,
//    aws_route_table.private-egress-gateway.*.id,
//    aws_route_table.private-egress-instance.*.id,
//    aws_route_table.private-egress-none.*.id
//  )
//}

//output "intra_route_table_ids" {
//  value = aws_route_table.intra.*.id
//}

# For whitelisting on 3rd party services
output "public_ips" {
  value = aws_eip.nat.*.public_ip
}

# Used to add additional rules
output "public_nacl_id" {
  value = aws_network_acl.public.id
}
output "public_egress_nacl_id" {
  value = aws_network_acl.public-egress.id
}
output "private_egress_nacl_id" {
  value = aws_network_acl.private-egress.id
}
output "private_nacl_id" {
  value = aws_network_acl.private.id
}

output "endpoint_security_group_id" {
  value = aws_security_group.endpoint.id
}
