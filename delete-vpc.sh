#!/bin/bash

# Set your values here
VPC_ID="vpc-016e9b14fefb948df"
REGION="us-east-1"
CLUSTER_NAME="roboshop"  # optional if EKS is already deleted

echo "🔍 Starting cleanup for VPC: $VPC_ID in region: $REGION"

# 1. Delete EKS Cluster if still present
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" > /dev/null 2>&1; then
  echo "🧨 Deleting EKS Cluster: $CLUSTER_NAME"
  aws eks delete-cluster --name "$CLUSTER_NAME" --region "$REGION"
else
  echo "✅ EKS Cluster $CLUSTER_NAME not found or already deleted"
fi

# 2. Delete EKS Nodegroups (if any)
for ng in $(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$REGION" --output text); do
  echo "🧨 Deleting Nodegroup: $ng"
  aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$ng" --region "$REGION"
done

# 3. Delete Fargate profiles (if any)
for fp in $(aws eks list-fargate-profiles --cluster-name "$CLUSTER_NAME" --region "$REGION" --output text); do
  echo "🧨 Deleting Fargate profile: $fp"
  aws eks delete-fargate-profile --cluster-name "$CLUSTER_NAME" --fargate-profile-name "$fp" --region "$REGION"
done

# 4. Delete NAT Gateways
for nat in $(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$VPC_ID --region $REGION --query 'NatGateways[*].NatGatewayId' --output text); do
  echo "🧨 Deleting NAT Gateway: $nat"
  aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region "$REGION"
done

# 5. Delete Network Interfaces
for eni in $(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$VPC_ID --region $REGION --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text); do
  echo "🧨 Deleting ENI: $eni"
  aws ec2 delete-network-interface --network-interface-id "$eni" --region "$REGION"
done

# 6. Delete VPC Endpoints
for ep in $(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$VPC_ID --region $REGION --query 'VpcEndpoints[*].VpcEndpointId' --output text); do
  echo "🧨 Deleting VPC Endpoint: $ep"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$ep" --region "$REGION"
done

# 7. Detach and delete Internet Gateways
for igw in $(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC_ID --region $REGION --query 'InternetGateways[*].InternetGatewayId' --output text); do
  echo "🔌 Detaching and deleting IGW: $igw"
  aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID" --region "$REGION"
  aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region "$REGION"
done

# 8. Delete subnets
for subnet in $(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --region $REGION --query 'Subnets[*].SubnetId' --output text); do
  echo "🧨 Deleting Subnet: $subnet"
  aws ec2 delete-subnet --subnet-id "$subnet" --region "$REGION"
done

# 9. Delete route tables (except main one first)
for rtb in $(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID --region $REGION --query 'RouteTables[*].RouteTableId' --output text); do
  is_main=$(aws ec2 describe-route-tables --route-table-ids $rtb --region $REGION --query 'RouteTables[*].Associations[*].Main' --output text)
  if [[ "$is_main" == "True" ]]; then
    echo "⚠️ Skipping main route table $rtb"
  else
    echo "🧨 Deleting route table: $rtb"
    aws ec2 delete-route-table --route-table-id "$rtb" --region "$REGION"
  fi
done

# 10. Delete security groups (except default)
for sg in $(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID --region $REGION --query 'SecurityGroups[*].GroupId' --output text); do
  if [[ "$sg" == $(aws ec2 describe-security-groups --group-ids "$sg" --region $REGION --query 'SecurityGroups[*].GroupName' --output text) == "default" ]]; then
    echo "⚠️ Skipping default SG: $sg"
  else
    echo "🧨 Deleting security group: $sg"
    aws ec2 delete-security-group --group-id "$sg" --region "$REGION"
  fi
done

# 11. Reassociate default DHCP options
DHCP_ID=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --region $REGION --query 'Vpcs[*].DhcpOptionsId' --output text)
if [[ "$DHCP_ID" != "dopt-*" ]]; then
  echo "🔁 Associating default DHCP options"
  aws ec2 associate-dhcp-options --dhcp-options-id default --vpc-id "$VPC_ID" --region "$REGION"
fi

# 12. Finally, delete the VPC
echo "🧨 Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION"

echo "✅ VPC and related resources deletion completed."
