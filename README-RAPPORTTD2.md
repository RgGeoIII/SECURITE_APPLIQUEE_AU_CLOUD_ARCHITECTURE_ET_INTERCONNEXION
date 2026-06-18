Sécurité appliquée au Cloud — TD1 & TD2

Mastère Cybersécurité · 5e année · École IPSSI — AWS Academy 2026

Xavier Rocher


TD1 — Sécuriser un réseau AWS : VPC, EC2, Security Groups & NACL

Schéma logique

Internet
   │
   ▼
[NACL xavier-nacl]
   │  Règle 100 : ALLOW TCP 22 depuis 82.96.161.255/32
   │  Règle 110 : ALLOW TCP 80 depuis 0.0.0.0/0
   │  Règle 200 : ALLOW TCP 1024-65535 depuis 0.0.0.0/0
   │  Sortie 90  : ALLOW TCP 80
   │  Sortie 91  : ALLOW TCP 443
   │  Sortie 100 : ALLOW TCP 1024-65535
   │
   ▼
Sous-réseau 172.31.190.0/24 — eu-west-3a
   │
   ├── [xavier-bastion-sg] SSH TCP 22 depuis 82.96.161.255/32 + HTTP 80
   │       └── xavier-bastion  IP publique
   │
   └── [xavier-cible-sg]  SSH + ICMP depuis xavier-bastion-sg
           └── xavier-cible    Sans IP publique

Réponses aux questions

Partie 1 — Explorer le VPC par défaut

Q1 — Plage du VPC et pourquoi les sous-réseaux sont « publics » ?

La plage est 172.31.0.0/16. Les sous-réseaux sont qualifiés de publics car la table de routage associée contient une route 0.0.0.0/0 → igw-… (Internet Gateway), ce qui permet à toute instance avec une IP publique d'être joignable depuis Internet.

Q2 — Sans sous-réseau privé, comment rendre une instance injoignable ?

En désactivant l'attribution automatique d'une IP publique (--no-associate-public-ip-address). Sans IP publique, l'Internet Gateway n'a aucune adresse à router vers l'instance.

Partie 2 — Lancer deux instances EC2

Q1 — Laquelle est joignable depuis Internet ?

Uniquement xavier-bastion, car c'est la seule avec une IP publique. xavier-cible est dans le même sous-réseau mais sans IP publique : elle est invisible depuis Internet.

Q2 — Comment atteindre la cible ?

Via un saut SSH par le bastion :

bashscp -i cle-xavier.pem cle-xavier.pem ubuntu@IP_BASTION:~/.ssh/
ssh -i cle-xavier.pem ubuntu@IP_BASTION
ssh -i ~/.ssh/cle-xavier.pem ubuntu@IP_PRIVEE_CIBLE

Partie 3 — Security Groups (stateful)

Q1 — Pourquoi référencer xavier-bastion-sg plutôt qu'une plage IP ?

L'IP privée du bastion peut changer en cas de redémarrage. En référençant le Security Group directement, AWS autorise dynamiquement tout trafic provenant de n'importe quelle instance attachée à ce SG.

Q2 — Pourquoi la réponse SSH repart sans règle de sortie explicite ?

Parce que les Security Groups sont stateful : ils mémorisent les connexions établies. La réponse à un flux entrant autorisé est automatiquement autorisée en sortie.

Partie 4 — NACL (stateless)

Q1 — Pourquoi autoriser 1024-65535 en sortie et non le port 22 ?

La réponse du serveur repart vers le port éphémère du client (port aléatoire entre 1024 et 65535). La NACL étant stateless, elle doit explicitement autoriser cette plage en sortie.

Q2 — Différence Security Group vs NACL ?

Un Security Group est stateful (trafic retour automatiquement autorisé) et s'applique à l'instance. Une NACL est stateless (chaque direction doit être explicitement autorisée) et s'applique à tout le sous-réseau.

Partie 5 — Défense en profondeur

Q1 — Si le SG autorise mais la NACL refuse, le trafic passe-t-il ?

Non. La NACL est évaluée en premier au niveau du sous-réseau. Si elle bloque le paquet, il n'atteint jamais l'instance.

Q2 — Avantage concret de deux couches de filtrage ?

Si un Security Group est mal configuré, la NACL constitue un filet de sécurité indépendant. Un attaquant doit contourner les deux barrières simultanément.

Bonnes pratiques retenues


Principe du moindre privilège : SSH restreint à une seule IP source (/32), jamais en 0.0.0.0/0
Isolation par absence d'IP publique : une instance sans IP publique est injoignable depuis Internet même dans un sous-réseau public
Référencer les Security Groups entre eux plutôt que des plages IP pour les règles inter-instances
Défense en profondeur : combiner NACL (sous-réseau) et Security Group (instance)
Ports éphémères : toujours ajouter la règle sortante 1024-65535 dans une NACL
Infrastructure as Code : toute la configuration est versionnée via Terraform
Ne jamais commiter de clé privée (.pem) dans un dépôt Git public



TD2 — Filtrage réseau et détection d'intrusion avec Terraform

Schéma logique

Internet
   │
   ├── [td2-27-sg-bastion] SSH depuis 82.96.161.255/32
   │       └── td2-27-bastion  IP publique (subnet 172.31.192.0/20)
   │               │
   │               ├── [td2-27-sg-prive] SSH depuis td2-27-sg-bastion
   │               │       └── td2-27-prive  Sans IP publique
   │               │               │
   │               │               └── NAT Gateway → Internet
   │               │
   │               └── [td2-27-sg-sonde] SSH + ICMP depuis td2-27-sg-bastion
   │                       └── td2-27-sonde  Suricata IDS
   │
   └── NAT Gateway (td2-27-nat) — EIP publique

Fichiers Terraform

FichierContenuprovider.tfProvider AWS + version requisevariables.tfRégion, AMI, type instance, clé, IP, numéro étudiantdata.tfVPC par défaut, subnet public, AMI Ubuntumain.tfInfrastructure TD1 (SG, instances, NACL)bastion.tfBastion TD2 + Security Groupegress.tfSubnet privé + NAT Gateway + instance privéesuricata.tfSonde Suricata via user_dataoutputs.tfIPs publiques et privées

Réponses aux questions

Partie 1 — Provider et data sources

Q1 — Différence resource vs data source ? Pourquoi le VPC en data source ?

Une resource est créée et gérée par Terraform (il peut la modifier et la supprimer). Une data source lit un objet existant sans le gérer. Le VPC par défaut est en data source pour qu'on puisse s'y rattacher sans risquer de le supprimer avec terraform destroy.

Q2 — À quoi sert terraform.tfstate ?

C'est le fichier où Terraform mémorise toutes les ressources qu'il a créées. Il permet à destroy de supprimer uniquement ce que Terraform a créé — le VPC par défaut (data source) ne figurant pas dans le state, il ne peut jamais être supprimé.

Partie 2 — Security Group et bastion

Q1 — Pourquoi pas besoin d'indiquer « crée le SG avant l'instance » ?

Terraform construit un graphe de dépendances automatiquement. L'instance référence aws_security_group.td2-bastion-sg.id, donc Terraform déduit qu'il doit créer le SG en premier.

Q2 — Que se passerait-il avec 0.0.0.0/0 sur le port 22 ?

SSH serait ouvert au monde entier — cible immédiate des scans automatiques et des attaques par force brute.

Partie 3 — NAT Gateway

Q1 — Quelle adresse renvoie curl checkip depuis l'instance privée ?

L'adresse IP publique de la NAT Gateway (l'EIP) : 35.181.189.23. Tout le trafic sortant est traduit derrière cette adresse partagée.

Q2 — Pourquoi la NAT Gateway doit être dans le sous-réseau public ?

La NAT a besoin d'une route vers l'Internet Gateway pour sortir sur Internet. Seul un sous-réseau public dispose de cette route (0.0.0.0/0 → igw).

Partie 4 — Suricata IDS

Q1 — Intérêt de passer l'installation en user_data ?

Reproductibilité — toute instance lancée avec ce code est configurée à l'identique, sans intervention manuelle. C'est le principe de l'infrastructure as code.

Q2 — Suricata détecte ou bloque le ping ?

Il détecte seulement (mode IDS) — on voit "action":"allowed" dans les logs eve.json. Un IPS placé en coupure pourrait en plus bloquer le trafic en temps réel avec une règle drop.

Alerte Suricata observée

json{
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

Bonnes pratiques retenues :

- data source vs resource : utiliser une data source pour les ressources        partagées qu'on ne doit jamais supprimer

- NAT Gateway : toujours dans le sous-réseau public, jamais dans le privé

- user_data : automatiser l'installation des outils de sécurité pour garantir la reproductibilité

- IDS vs IPS : Suricata en mode alerte (IDS) détecte sans bloquer — un IPS bloquerait en temps réel

- terraform destroy : obligatoire en fin de session pour éviter les coûts (NAT Gateway facturée à l'heure)

- Numéro étudiant : utiliser un identifiant unique pour éviter les collisions de noms et CIDRs en environnement partagé
