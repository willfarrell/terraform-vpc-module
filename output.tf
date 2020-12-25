output "id" {
  value = aws_vpc.main.id
}

# For bastion, proxy
output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

# For ECS, RDS, etc
output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

# For Task runners, etc
//output "intra_subnet_ids" {
//  value = aws_subnet.intra.*.id
//}

# For VPC endpoints
output "private_route_table_ids" {
  value = concat(
    aws_route_table.private.*.id,
    aws_route_table.private-gateway.*.id,
    aws_route_table.private-instance.*.id
  )
}

//output "intra_route_table_ids" {
//  value = aws_route_table.intra.*.id
//}

# For whitelisting on 3rd party services
output "public_ips" {
  value = aws_eip.nat.*.public_ip
}

# Used to add additional rules
output "network_acl_id" {
  value = aws_network_acl.public.id
}

output "security_group_id" {
  value = aws_default_security_group.default.id
}
