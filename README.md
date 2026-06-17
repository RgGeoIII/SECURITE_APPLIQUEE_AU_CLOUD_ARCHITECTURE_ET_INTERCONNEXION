# ☁️ Sécurité appliquée au Cloud AWS

Ce projet regroupe mes TDs et TPs du module **Sécurité appliquée au Cloud** — VPC, Security Groups, NACL, Terraform, Suricata — réalisés dans le cadre du Mastère Cybersécurité & Cloud Computing à l'IPSSI.

---

## 📁 Structure du projet

- `TD/TP_1/` : TD Jour 1 — VPC, Security Groups, NACL (CLI AWS)
- `TD/TP_2/` : TD Jour 2 — Infrastructure as Code avec Terraform, NAT Gateway, Suricata IDS
- `services/` : Scripts Bash AWS CLI (création NACL, règles d'entrée)
- `ansible/` : Fichiers d'inventaire et playbooks Ansible
- `infra/` : Ressources infrastructure complémentaires

---

## 🎯 Objectifs pédagogiques

- Explorer et sécuriser un VPC AWS par défaut (172.31.0.0/16)
- Configurer des Security Groups (stateful) et des NACL (stateless)
- Comprendre la défense en profondeur (NACL + SG)
- Provisionner une infrastructure complète avec Terraform (IaC)
- Déployer un sous-réseau privé avec NAT Gateway
- Installer et configurer une sonde Suricata IDS via `user_data`

---

## 🗂️ Contenu des TPs

### TP1 — VPC, Security Groups & NACL (CLI AWS)
- Exploration du VPC par défaut
- Lancement de deux instances EC2 (bastion public + cible privée)
- Création de Security Groups avec règles SSH et ICMP
- Création d'une NACL custom et observation du comportement stateless
- Défense en profondeur : NACL deny vs SG allow

### TP2 — Terraform, NAT Gateway & Suricata
- Provider AWS + data sources (VPC par défaut)
- Security Group bastion (SSH depuis IP dynamique via checkip.amazonaws.com)
- Sous-réseau public et privé, NAT Gateway, route table
- Instance privée sans IP publique (sortie Internet via NAT)
- Sonde Suricata déployée via `user_data` sur Ubuntu 22.04
- Règle ICMP custom et observation des alertes dans `eve.json`

---

## 🛠️ Prérequis

- AWS CLI configuré (`aws configure`)
- Terraform ≥ 1.0
- Une paire de clés EC2 dans la région `eu-west-3`
- Accès IAM avec full access VPC et EC2

---

## 🚀 Utilisation (TP2 Terraform)

```bash
cd TD/TP_2
terraform init
terraform plan
terraform apply
# Ne pas oublier de détruire après le TD !
terraform destroy
```

---

## ⚠️ Bonnes pratiques

- Ne jamais committer de fichiers `.pem`, `.tfstate` ou `.tfstate.backup`
- Ne jamais ouvrir SSH (port 22) sur `0.0.0.0/0`
- Toujours lancer `terraform destroy` après le TD (NAT Gateway facturée à l'heure)
- Travailler uniquement dans `eu-west-3` et dans le VPC par défaut partagé

---

## 🛡️ Prérequis

- AWS CLI + Terraform installés
- Région : `eu-west-3` (Paris)
- Instance type : `t2.micro`

---

## 🤖 Auteur

**Geoffrey Rouvel**  
Étudiant à l'IPSSI | Mastère Cybersécurité & Cloud Computing  
GitHub : [@RgGeoIII](https://github.com/RgGeoIII)

---

## 🤖 Collaborateur

**Xavier ROCHER**  
Étudiant à l’IPSSI | Administrateur Systèmes & Réseaux  
GitHub : [@Xavier-ROCHER](https://github.com/Xavier-ROCHER)

**Ludovic MANGENOT**  
Étudiant à l’IPSSI | Administrateur Systèmes & Réseaux  
GitHub : [@Ludovic MANGENOT](https://github.com/LudovicMangenot)

---

🎓 Projet réalisé dans le cadre du module **Sécurité appliquée au Cloud - Architecture & Interconnexion** — École IPSSI, AWS Academy, Édition 2026.
