#!/usr/bin/env bash

echo "***** Update *****"
yum update -y

echo "***** Instance ENV *****"
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_ID=$(curl -s -m 60 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(echo $AVAILABILITY_ZONE | sed 's/.$//')

echo "***** Setup NAT Settings *****"
aws ec2 --region $REGION modify-instance-attribute --no-source-dest-check --instance-id $INSTANCE_ID

# https://aws.amazon.com/premiumsupport/knowledge-center/vpc-nat-instance/
# For larger instances only
# error: "net.ipv4.netfilter.ip_conntrack_max" is an unknown key
cat << EOF > /etc/sysctl.d/custom_nat_tuning.conf
# for large instance types, allow keeping track of more
# connections (requires enough RAM)
net.ipv4.netfilter.ip_conntrack_max=262144
EOF
sysctl -p /etc/sysctl.d/custom_nat_tuning.conf

echo "***** Setup Networking Route Table *****"
aws ec2 --region $REGION delete-route --destination-cidr-block 0.0.0.0/0 --route-table-id ${ROUTE_TABLE_ID}
aws ec2 --region $REGION delete-route --destination-ipv6-cidr-block ::/0 --route-table-id ${ROUTE_TABLE_ID}
aws ec2 --region $REGION create-route --destination-cidr-block 0.0.0.0/0 --route-table-id ${ROUTE_TABLE_ID} --instance-id $INSTANCE_ID
aws ec2 --region $REGION create-route --destination-ipv6-cidr-block ::/0 --route-table-id ${ROUTE_TABLE_ID} --instance-id $INSTANCE_ID

echo "***** Attach IP [Public Subnet Only] *****"
aws --region $REGION ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${EIP_ID}
