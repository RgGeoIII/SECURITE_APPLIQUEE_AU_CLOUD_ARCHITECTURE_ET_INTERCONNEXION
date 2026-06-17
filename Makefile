ANSIBLE_DIR := infra/ansible
TF_DIR := infra/terraform
INFO_COLOR := \033[36;1m 
NO_COLOR := \033[0m # Bonnes pratiques

# .PHONY Permet dire à make que ce ne sont pas des fichiers mais des commandes

.PHONY: help tr_lint tr_plan tr_apply

.DEFAULT_GOAL := help

help: ## shows this helps
	@grep -E "^[a-zA-Z_-]+.*: ## .*$$" $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=": ##"}{printf "$(INFO_COLOR)%-20s$(NO_COLOR)%s\n", $$1, $$2}'

tr_lint: ## format and validate terraform configs
	@cd $(TF_DIR) && terraform fmt && terraform validate

tr_plan: tr_lint
	@cd $(TF_DIR) && terraform plan

tr_apply: tr_plan
	@cd $(TF_DIR) && terraform apply

tr_output: ## outputs ip
	@echo "[web]" > $(ANSIBLE_DIR)/inventory.ini
	@echo "$(terraform output vm_public_ip) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ludo_aws_key" >> $(ANSIBLE_DIR)/inventory.ini

play: ## runs the playbook
	@ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/nginx.yml


build: tr_apply tr_output play