#!/bin/bash

# Charger les variables (VPC_ID)
source "$(dirname "$0")/../constants/variables.sh"

# Variables locales
MY_IP="82.96.161.255/32"
SUBNET_ID="subnet-04c68e8462b800631"

# ── Créer la NACL ────────────────────────────────────────────────────
create_nacl() {
    local nacl_name="$1"
    aws_response=$(aws ec2 create-network-acl \
        --region eu-west-3 \
        --vpc-id "$VPC_ID" \
        --tag-specifications "ResourceType=network-acl,Tags=[{Key=Name,Value=$nacl_name}]")

    echo "$aws_response" > nacl.json
}

# ── Règle ENTRANTE (ingress) ─────────────────────────────────────────
create_ingress_rule() {
    local network_acl_id="$1"
    local rule_number="$2"
    local protocol=${3:-6}
    local from=${4:-22}
    local to=${5:-22}
    local cidr=${6:-$MY_IP}
    local rule_action=${7:-"allow"}

    aws ec2 create-network-acl-entry \
        --region eu-west-3 \
        --network-acl-id "$network_acl_id" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range From="$from",To="$to" \
        --cidr-block "$cidr" \
        --rule-action "$rule_action" \
        --ingress
}

# ── Règle SORTANTE (egress) — ports éphémères ────────────────────────
create_egress_rule() {
    local network_acl_id="$1"
    local rule_number="$2"
    local protocol=${3:-6}
    local from=${4:-1024}
    local to=${5:-65535}
    local cidr=${6:-"0.0.0.0/0"}
    local rule_action=${7:-"allow"}

    aws ec2 create-network-acl-entry \
        --region eu-west-3 \
        --network-acl-id "$network_acl_id" \
        --rule-number "$rule_number" \
        --protocol "$protocol" \
        --port-range From="$from",To="$to" \
        --cidr-block "$cidr" \
        --rule-action "$rule_action" \
        --egress
}

# ── Associer la NACL au sous-réseau ──────────────────────────────────
associate_nacl() {
    local network_acl_id="$1"

    ASSOC_ID=$(aws ec2 describe-network-acls \
        --region eu-west-3 \
        --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
        --query "NetworkAcls[].Associations[?SubnetId=='$SUBNET_ID'].NetworkAclAssociationId" \
        --output text)

    echo "Association actuelle : $ASSOC_ID (notez-la pour le nettoyage !)"

    aws ec2 replace-network-acl-association \
        --region eu-west-3 \
        --association-id "$ASSOC_ID" \
        --network-acl-id "$network_acl_id"
}

# ── Supprimer la NACL ────────────────────────────────────────────────
delete_nacl() {
    local nacl_id="$1"
    aws ec2 delete-network-acl \
        --region eu-west-3 \
        --network-acl-id "$nacl_id"
    echo "NACL $nacl_id supprimée"
}

# ════════════════════════════════════════════════════════════════════
# EXÉCUTION
# ════════════════════════════════════════════════════════════════════

echo "VPC_ID utilisé : $VPC_ID"

# 1. Créer la NACL
create_nacl "$1"

# 2. Extraire le NetworkAclId
NETWORK_ACL_ID=$(grep -o '"NetworkAclId": *"[^"]*"' nacl.json | sed 's/"NetworkAclId": *"\([^"]*\)"/\1/')
echo "NetworkAclId récupéré : $NETWORK_ACL_ID"

# 3. Règle entrante : SSH depuis mon IP (allow)
create_ingress_rule "$NETWORK_ACL_ID" 100
echo "Règle entrante SSH ajoutée"

# 4. Règle sortante : ports éphémères
create_egress_rule "$NETWORK_ACL_ID" 100
echo "Règle sortante ports éphémères ajoutée"

# 5. Associer la NACL au sous-réseau
associate_nacl "$NETWORK_ACL_ID"
echo "NACL associée au sous-réseau $SUBNET_ID"