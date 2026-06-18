#!/bin/bash
# Installation des dépendances système
yum update -y
yum install -y python3 python3-pip

# Installation des packages Python
pip3 install flask gunicorn requests

# Création du dossier de l'application
mkdir -p /app

# DNS de l'ALB interne injecté par Terraform via templatefile
cat > /app/.env << ENVEOF
INTERNAL_ALB_DNS=${internal_alb_dns}
ENVEOF

# Code du serveur web
cat > /app/web.py << 'WEBEOF'
import os
import requests
from flask import Flask, request, render_template_string

app = Flask(__name__)

# Chargement du DNS de l'ALB interne
from dotenv import load_dotenv
load_dotenv("/app/.env")

APP_API_URL = f"http://{os.environ['INTERNAL_ALB_DNS']}/api/signup"

FORM = """
<!doctype html>
<title>Inscription</title>
<h1>Créer un compte</h1>
{% if message %}
  <p style="color: {{ color }}">{{ message }}</p>
{% endif %}
<form method="post" action="/signup">
  <input name="full_name" placeholder="Nom complet"><br><br>
  <input name="email" type="email" placeholder="Email" required><br><br>
  <input name="password" type="password" placeholder="Mot de passe" required><br><br>
  <button type="submit">S'inscrire</button>
</form>
"""

@app.get("/health")
def health():
    return "ok", 200

@app.get("/")
def form():
    return render_template_string(FORM, message=None)

@app.post("/signup")
def signup():
    full_name = request.form.get("full_name")
    email = request.form.get("email")
    password = request.form.get("password")

    try:
        # Appel vers l'API interne via l'ALB interne
        response = requests.post(
            APP_API_URL,
            json={"email": email, "password": password, "full_name": full_name},
            timeout=5
        )

        if response.status_code == 201:
            return render_template_string(FORM, message="Inscription réussie !", color="green")
        elif response.status_code == 400:
            return render_template_string(FORM, message="Données invalides.", color="red")
        elif response.status_code == 409:
            return render_template_string(FORM, message="Email déjà utilisé.", color="orange")
        else:
            return render_template_string(FORM, message="Erreur serveur.", color="red")

    except Exception as e:
        return render_template_string(FORM, message=f"Erreur : {str(e)}", color="red")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
WEBEOF

# Installation de python-dotenv
pip3 install python-dotenv

# Lancement du serveur web avec gunicorn
gunicorn --bind 0.0.0.0:80 --workers 2 --chdir /app web:app &
