# Sécurité appliquée au Cloud — TD1, TD2 & TD3

**Mastère Cybersécurité · 5e année · École IPSSI — AWS Academy 2026**  
Xavier Rocher / Geoffrey ROUVEL / Ludovic MANGENOT

---

## TD1 — Sécuriser un réseau AWS : VPC, EC2, Security Groups & NACL

### Schéma logique

```
Internet
   │
[NACL xavier-nacl]
   │  Règle 100 : ALLOW TCP 22 depuis 82.96.161.255/32
   │  Règle 110 : ALLOW TCP 80 depuis 0.0.0.0/0
   │  Règle 200 : ALLOW TCP 1024-65535
   │  Sortie 90  : ALLOW TCP 80
   │  Sortie 91  : ALLOW TCP 443
   │  Sortie 100 : ALLOW TCP 1024-65535
   │
Sous-réseau 172.31.190.0/24 — eu-west-3a
   │
   ├── [xavier-bastion-sg] SSH depuis 82.96.161.255/32
   │       └── xavier-bastion  IP publique
   │
   └── [xavier-cible-sg] SSH + ICMP depuis xavier-bastion-sg
           └── xavier-cible    Sans IP publique
```

### Réponses aux questions

**Partie 1 — Explorer le VPC par défaut**

Q1 — La plage est `172.31.0.0/16`. Les sous-réseaux sont publics car la table de routage contient une route `0.0.0.0/0 → igw-…`, ce qui permet à toute instance avec une IP publique d'être joignable depuis Internet.

Q2 — En désactivant l'attribution automatique d'une IP publique (`--no-associate-public-ip-address`). Sans IP publique, l'Internet Gateway n'a aucune adresse à router vers l'instance.

**Partie 2 — Lancer deux instances EC2**

Q1 — Uniquement `xavier-bastion`, car c'est la seule avec une IP publique. `xavier-cible` est dans le même sous-réseau mais sans IP publique : elle est invisible depuis Internet.

Q2 — Via un saut SSH par le bastion : on se connecte au bastion, puis SSH vers l'IP privée de la cible.

**Partie 3 — Security Groups**

Q1 — L'IP privée du bastion peut changer en cas de redémarrage. En référençant le Security Group directement, AWS autorise dynamiquement tout trafic provenant de n'importe quelle instance attachée à ce SG.

Q2 — Parce que les Security Groups sont stateful : ils mémorisent les connexions établies. La réponse à un flux entrant autorisé est automatiquement autorisée en sortie.

**Partie 4 — NACL**

Q1 — La réponse du serveur repart vers le port éphémère du client (entre 1024 et 65535). La NACL étant stateless, elle doit explicitement autoriser cette plage en sortie.

Q2 — Un Security Group est stateful (trafic retour automatiquement autorisé) et s'applique à l'instance. Une NACL est stateless (chaque direction doit être explicitement autorisée) et s'applique à tout le sous-réseau.

**Partie 5 — Défense en profondeur**

Q1 — Non. La NACL est évaluée en premier au niveau du sous-réseau. Si elle bloque le paquet, il n'atteint jamais l'instance.

Q2 — Si un Security Group est mal configuré, la NACL constitue un filet de sécurité indépendant. Un attaquant doit contourner les deux barrières simultanément.

### Bonnes pratiques retenues

- Principe du moindre privilège : SSH restreint à une seule IP source (/32)
- Isolation par absence d'IP publique
- Référencer les Security Groups entre eux plutôt que des plages IP
- Défense en profondeur : combiner NACL et Security Group
- Toujours ajouter la règle sortante 1024-65535 dans une NACL
- Infrastructure as Code versionnée via Terraform
- Ne jamais commiter de clé privée (.pem) dans un dépôt Git

---

## TD2 — Filtrage réseau et détection d'intrusion avec Terraform

### Schéma logique

```
Internet
   │
   ├── [td2-27-sg-bastion] SSH depuis 82.96.161.255/32
   │       └── td2-27-bastion  IP publique
   │               │
   │               ├── [td2-27-sg-prive] SSH depuis td2-27-sg-bastion
   │               │       └── td2-27-prive  Sans IP publique → NAT Gateway → Internet
   │               │
   │               └── [td2-27-sg-sonde] SSH + ICMP depuis td2-27-sg-bastion
   │                       └── td2-27-sonde  Suricata IDS
   │
   └── NAT Gateway (td2-27-nat)
```

### Réponses aux questions

**Partie 1 — Provider et data sources**

Q1 — Une resource est créée et gérée par Terraform. Une data source lit un objet existant sans le gérer. Le VPC par défaut est en data source pour qu'on ne puisse jamais le supprimer avec `terraform destroy`.

Q2 — Le fichier `terraform.tfstate` mémorise toutes les ressources créées. Il permet à `destroy` de supprimer uniquement ce que Terraform a créé.

**Partie 2 — Security Group et bastion**

Q1 — Terraform construit un graphe de dépendances automatiquement. L'instance référence `aws_security_group.td2-bastion-sg.id`, donc Terraform crée le SG en premier.

Q2 — SSH serait ouvert au monde entier, cible immédiate des scans automatiques et des attaques par force brute.

**Partie 3 — NAT Gateway**

Q1 — L'adresse IP publique de la NAT Gateway (EIP). Tout le trafic sortant est traduit derrière cette adresse partagée.

Q2 — La NAT a besoin d'une route vers l'Internet Gateway pour sortir sur Internet. Seul un sous-réseau public dispose de cette route.

**Partie 4 — Suricata**

Q1 — Reproductibilité : toute instance lancée avec ce code est configurée à l'identique, sans intervention manuelle.

Q2 — Il détecte seulement (mode IDS), on voit `"action":"allowed"` dans les logs. Un IPS bloquerait le trafic en temps réel avec une règle `drop`.

### Alerte Suricata observée

```json
{
  "timestamp": "2026-06-18T09:23:50",
  "src_ip": "172.31.195.180",
  "dest_ip": "172.31.207.162",
  "proto": "ICMP",
  "alert": {
    "action": "allowed",
    "signature_id": 1000001,
    "signature": "TD2 ICMP detecte",
    "severity": 3
  }
}
```

---

## TD3 — Application web 3-tiers sur AWS

### Schéma logique

```
Internet
   │
   ▼
ALB PUBLIC (xavier-td3-alb-public)
   │  subnets publics 172.31.60-61.0/24
   ▼
TIER WEB — Flask (xavier-td3-web-0/1)
   │  subnets privés web 172.31.70-71.0/24
   │  formulaire d'inscription
   ▼
ALB INTERNE (xavier-td3-alb-internal)
   │  subnets privés app 172.31.80-81.0/24
   ▼
TIER APP — API Flask (xavier-td3-app-0/1)
   │  subnets privés app 172.31.80-81.0/24
   │  POST /api/signup
   ▼
RDS PostgreSQL (td-ipssi-rds-v2)
   │  subnets privés data 172.31.82-83.0/24
   │  table users
```

### Flux d'une inscription

1. Le navigateur fait `GET /` sur le DNS de l'ALB public → ALB transmet au tier web → Flask renvoie le formulaire HTML
2. L'utilisateur remplit le formulaire et clique S'inscrire → `POST /signup` → ALB public → tier web
3. Le tier web appelle en interne `POST /api/signup` sur le DNS de l'ALB interne → tier app
4. Le tier app valide les données, hache le mot de passe, ouvre une connexion PostgreSQL et exécute un `INSERT`
5. RDS confirme → l'API renvoie 201 → le tier web affiche "Inscription réussie !"

### Infrastructure Terraform

| Fichier | Contenu |
|---------|---------|
| `providers.tf` | Provider AWS |
| `variables.tf` | Région, AZs, CIDRs, credentials DB |
| `network.tf` | Subnets, NAT Gateways, tables de routage |
| `security.tf` | 5 Security Groups en chaîne |
| `data.tf` | Référence au RDS partagé |
| `app_tier.tf` | ALB interne + instances app + target group |
| `web_tier.tf` | ALB public + instances web + target group |
| `outputs.tf` | URL du site, DNS ALB interne |

### Réponses aux questions

**Question 1 — Pourquoi une NAT Gateway par AZ ?**

Si l'unique NAT Gateway était dans l'AZ-a et que l'AZ-a tombe, toutes les instances privées de l'AZ-b perdraient leur accès Internet. En déployant une NAT par AZ, chaque zone est autonome : si l'AZ-a tombe, les instances de l'AZ-b continuent de sortir via leur propre NAT. C'est la haute disponibilité.

**Question 2 — Un attaquant ayant compromis le tier web peut-il accéder directement à RDS ?**

Non. Le SG de RDS n'autorise en entrée que le port 5432 depuis `SG-app`. Le tier web est attaché à `SG-web`, pas à `SG-app`. Même compromis, il ne peut pas se connecter directement à la base car son SG n'est pas autorisé. L'attaquant devrait d'abord compromettre une instance du tier app.

**Question 3 — Pourquoi `publicly_accessible = false` ET le subnet privé sont-ils tous les deux nécessaires ?**

`publicly_accessible = false` empêche AWS d'attribuer une IP publique à RDS. Le subnet privé empêche le routage depuis Internet. Les deux sont nécessaires car l'un sans l'autre laisse une faille : un subnet privé avec `publicly_accessible = true` attribuerait quand même une IP publique résolvable, et `publicly_accessible = false` dans un subnet public n'empêche pas un accès depuis d'autres ressources du VPC non autorisées.

**Question 4 — Pourquoi ne pas interroger RDS dans le health check de l'ALB ?**

Si RDS est temporairement surchargé ou lent, toutes les instances app seraient marquées `unhealthy` et retirées de la rotation, rendant l'API indisponible alors qu'elle fonctionne correctement. Un health check sur `/health` (qui retourne juste "ok") vérifie uniquement que le processus Flask tourne, indépendamment de l'état de la base.

**Question 5 — Chemin d'une requête d'inscription (aller et retour)**

Aller :
1. Navigateur → DNS ALB public (Internet)
2. ALB public → instance web (subnet privé web, via SG-alb-public → SG-web)
3. Instance web → DNS ALB interne (interne VPC)
4. ALB interne → instance app (subnet privé app, via SG-alb-internal → SG-app)
5. Instance app → RDS PostgreSQL port 5432 (subnet privé data, via SG-app → SG-rds)

Retour :
1. RDS → instance app (réponse SQL)
2. Instance app → ALB interne (réponse JSON 201)
3. ALB interne → instance web (réponse JSON)
4. Instance web → ALB public (page HTML de confirmation)
5. ALB public → navigateur (HTTP 200)

### Résultat du test

- Formulaire accessible sur `http://xavier-td3-alb-public-1181942315.eu-west-3.elb.amazonaws.com`
- Inscription réussie avec message de confirmation
- Ligne créée dans la table `users` de la base `mydb`
- L'ALB interne et RDS sont inaccessibles depuis Internet

### Bonnes pratiques retenues

- Architecture 3-tiers : séparation présentation / application / données
- Deux ALB : cloisonnement réel, le tier app n'est jamais exposé à Internet
- Security Groups en chaîne : chaque couche n'accepte que la couche du dessus
- NAT Gateway par AZ pour la haute disponibilité
- RDS Multi-AZ : failover automatique en cas de panne d'une AZ
- `publicly_accessible = false` + subnet privé pour RDS
- Health check léger sur `/health` sans interroger la base
- Mot de passe haché avant stockage (sha256 + sel)
- Requêtes SQL paramétrées (anti-injection SQL)
- Infrastructure as Code : tout reproductible avec `terraform apply`
