#!/bin/bash

read -p "Entrer l'id du VPC : " vpc_id


nacl_name="$1"
rule_number="$2"
protocol="$3"
from="$4"
to="$5"
rule_action="$6"
cidr_block="$7"

delete_nacl() {
    local nacl_id="$1"
    aws_response=$(aws ec2 delete-network-acl --network-acl-id "$nacl_id")
    echo "$aws_response" > nacl.json
}

create_nacl() {
    aws_response=$(aws ec2 create-network-acl \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=$nacl_name}]")
    echo "$aws_response" > nacl.json

    NACL_ID=$(echo "$aws_response" | grep -o '"NetworkAclId": "[^"]*"' | grep -o 'acl-[^"]*')
    echo "NACL créé avec l'ID : $NACL_ID"
}

create_ingress_rule() {
    aws ec2 create-network-acl-entry \
        --network-acl-id "$NACL_ID" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range "From=$from,To=$to" \
        --cidr-block "$cidr_block" \
        --rule-action "$rule_action" \
        --ingress
}

create_nacl
create_ingress_rule