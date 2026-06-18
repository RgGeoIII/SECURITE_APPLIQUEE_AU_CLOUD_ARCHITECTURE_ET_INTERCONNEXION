# Sécurité appliquée au Cloud — Jour 1 · TD

**Sécuriser un réseau AWS : VPC, EC2, Security Groups & NACL**  
Mastère Cybersécurité · 5e année · École IPSSI — AWS Academy 2026  
Xavier Rocher

---

## Schéma logique de l'infrastructure

```
Internet
   │
   ▼
[NACL td-nacl]
   │  Règle 90 : DENY  TCP 22 depuis 82.96.161.255/32
   │  Règle 100 : ALLOW TCP 22 depuis 82.96.161.255/32
   │  Sortie  100 : ALLOW TCP 1024-65535 vers 0.0.0.0/0
   │
   ▼
Sous-réseau 172.31.190.0/24 — eu-west-3a
   │
   ├── [sg-bastion] SSH TCP 22 depuis 82.96.161.255/32
   │       └── td-bastion  IP publique : 51.44.223.103
   │                       IP privée  : 172.31.190.89
   │
   └── [sg-cible]  SSH + ICMP depuis sg-bastion uniquement
           └── td-cible    Pas d'IP publique
                           IP privée  : 172.31.190.219
```

| Ressource | Valeur |
|-----------|--------|
| VPC par défaut | `vpc-0ebcdb39f7a526ef9` — 172.31.0.0/16 — eu-west-3 |
| Sous-réseau | `subnet-079a2cdda0fa39ddd` — 172.31.190.0/24 — eu-west-3a |
| td-bastion | IP publique `51.44.223.103` — Ubuntu 24.04 — t3.micro |
| td-cible | Sans IP publique — IP privée `172.31.190.219` — Ubuntu 24.04 — t3.micro |
| sg-bastion | SSH TCP 22 depuis `82.96.161.255/32` |
| sg-cible | SSH + ICMP depuis `sg-bastion` |
| td-nacl | Règle 90 DENY + Règle 100 ALLOW TCP 22 — Sortie 1024-65535 |

---

## Réponses aux questions

### Partie 1 — Explorer le VPC par défaut

**Q1 — Plage du VPC et pourquoi les sous-réseaux sont « publics » ?**  
La plage est `172.31.0.0/16`. Les sous-réseaux sont qualifiés de publics car la table de routage associée contient une route `0.0.0.0/0 → igw-…` (Internet Gateway), ce qui permet à toute instance avec une IP publique d'être joignable depuis Internet.

**Q2 — Sans sous-réseau privé, comment rendre une instance injoignable ?**  
En désactivant l'attribution automatique d'une IP publique (`--no-associate-public-ip-address`). Sans IP publique, l'Internet Gateway n'a aucune adresse à router vers l'instance.

---

### Partie 2 — Lancer deux instances EC2

**Q1 — Laquelle est joignable depuis Internet ?**  
Uniquement `td-bastion`, car c'est la seule avec une IP publique. `td-cible` est dans le même sous-réseau mais sans IP publique : elle est invisible depuis Internet.

**Q2 — Comment atteindre la cible ?**  
Via un saut SSH par le bastion :
```bash
# Copier la clé sur le bastion
scp -i cle-td.pem cle-td.pem ubuntu@51.44.223.103:~/.ssh/

# Se connecter au bastion
ssh -i cle-td.pem ubuntu@51.44.223.103

# Depuis le bastion, SSH vers la cible
ssh -i ~/.ssh/cle-td.pem ubuntu@172.31.190.219
```

---

### Partie 3 — Security Groups (stateful)

**Q1 — Pourquoi référencer `sg-bastion` plutôt qu'une plage IP ?**  
L'IP privée du bastion peut changer en cas de redémarrage. En référençant le Security Group directement, AWS autorise dynamiquement tout trafic provenant de n'importe quelle instance attachée à ce SG, sans dépendre d'une adresse IP fixe.

**Q2 — Pourquoi la réponse SSH repart sans règle de sortie explicite ?**  
Parce que les Security Groups sont **stateful** : ils mémorisent les connexions établies. La réponse à un flux entrant autorisé est automatiquement autorisée en sortie.

---

### Partie 4 — NACL (stateless)

**Q1 — Pourquoi autoriser 1024-65535 en sortie et non le port 22 ?**  
La réponse du serveur repart vers le **port éphémère du client** (un port aléatoire entre 1024 et 65535 choisi par l'OS), pas vers le port 22. La NACL étant stateless, elle doit explicitement autoriser cette plage en sortie, sinon les réponses sont bloquées.

**Q2 — Différence Security Group vs NACL ?**  
Un Security Group est **stateful** (trafic retour automatiquement autorisé) et s'applique à l'**instance**, tandis qu'une NACL est **stateless** (chaque direction doit être explicitement autorisée) et s'applique à tout le **sous-réseau**.

---

### Partie 5 — Défense en profondeur

**Q1 — Si le SG autorise mais la NACL refuse, le trafic passe-t-il ?**  
Non. La NACL est évaluée **en premier** au niveau du sous-réseau. Si elle bloque le paquet, il n'atteint jamais l'instance et le Security Group n'est pas consulté.

**Q2 — Avantage concret de deux couches de filtrage ?**  
Si un Security Group est mal configuré suite à une erreur humaine, la NACL constitue un **filet de sécurité indépendant**. Un attaquant doit contourner les deux barrières simultanément.

---

## Infrastructure Terraform

```hcl
# Security Group Bastion — SSH depuis mon IP uniquement
resource "aws_security_group" "xavbastion-sg" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.96.161.255/32"]
  }
}

# Security Group Cible — SSH + ICMP depuis le bastion uniquement
resource "aws_security_group" "xavcible-sg" {
  ingress {
    from_port       = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.xavbastion-sg.id]
  }
}

# NACL — Partie 6 : deny prioritaire sur allow
resource "aws_network_acl" "td_nacl" {
  ingress {
    rule_no    = 90
    action     = "deny"    # bloque SSH même si le SG autorise
    protocol   = "tcp"
    from_port  = 22
    cidr_block = "82.96.161.255/32"
  }
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    cidr_block = "82.96.161.255/32"
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024      # ports éphémères indispensables
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
}
```

---

## Bonnes pratiques retenues

- **Principe du moindre privilège** : SSH restreint à une seule IP source (`/32`), jamais en `0.0.0.0/0`
- **Isolation par absence d'IP publique** : une instance sans IP publique est injoignable depuis Internet même dans un sous-réseau public
- **Référencer les Security Groups entre eux** plutôt que des plages IP pour les règles inter-instances
- **Défense en profondeur** : combiner NACL (sous-réseau) et Security Group (instance) pour deux couches indépendantes
- **Ports éphémères** : toujours ajouter la règle sortante 1024-65535 dans une NACL pour ne pas bloquer le trafic retour
- **Infrastructure as Code** : toute la configuration est versionnée, reproductible et auditable via Terraform
- **Ne jamais commiter de clé privée** (`.pem`) dans un dépôt Git public
