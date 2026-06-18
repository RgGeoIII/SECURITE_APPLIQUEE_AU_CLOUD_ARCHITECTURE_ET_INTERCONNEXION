#!/bin/bash
# Installation des dépendances système
yum update -y
yum install -y python3 python3-pip

# Installation des packages Python
pip3 install flask gunicorn psycopg2-binary

# Création du dossier de l'application
mkdir -p /app

# Variables d'environnement injectées par Terraform via templatefile
cat > /app/.env << ENVEOF
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}
ENVEOF

# Copie du code de l'application
cat > /app/app.py << 'APPEOF'
import os
import hashlib
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

# Chargement des variables d'environnement
from dotenv import load_dotenv
load_dotenv("/app/.env")

DB_CONFIG = {
    "host": os.environ["DB_HOST"],
    "dbname": os.environ["DB_NAME"],
    "user": os.environ["DB_USER"],
    "password": os.environ["DB_PASSWORD"],
    "port": 5432,
}

@app.get("/health")
def health():
    return "ok", 200

@app.post("/api/signup")
def signup():
    data = request.get_json(force=True)
    email = data.get("email")
    password = data.get("password")
    full_name = data.get("full_name")

    if not email or "@" not in email:
        return jsonify({"error": "Email invalide"}), 400
    if not password:
        return jsonify({"error": "Mot de passe requis"}), 400

    # Hachage du mot de passe avec sel
    salt = os.urandom(16).hex()
    password_hash = hashlib.sha256((salt + password).encode()).hexdigest()

    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO users (email, password_hash, full_name) VALUES (%s, %s, %s)",
            (email, password_hash, full_name)
        )
        conn.commit()
        cur.close()
        conn.close()
    except psycopg2.errors.UniqueViolation:
        return jsonify({"error": "Email deja utilise"}), 409
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify({"status": "created", "email": email}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
APPEOF

# Installation de python-dotenv
pip3 install python-dotenv

# Lancement de l'application avec gunicorn
gunicorn --bind 0.0.0.0:80 --workers 2 --chdir /app app:app &
