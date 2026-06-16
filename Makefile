TF_DIR := infra/terraform
AN_DIR := infra/ansible
INFO_COLOR := \033[36;1m
NO_COLOR := \033[0m

.PHONY: help tr_fmt 
.DEFAULT_GOAL := help

help: ## show this helps
	@grep -E "^[a-zA-Z_-]+.*: ## .*$$" $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=": ##"}{ printf "$(INFO_COLOR)%-20s$(NO_COLOR)%s\n", $$1, $$2}'

tr_fmt: ## format terraform configs
	@cd $(TF_DIR) && terraform fmt

tr_validate: tr_fmt
	@cd $(TF_DIR) terraform plan && terraform validate

tr_plan_apply: tr_validate
	@cd $(TF_DIR) terraform plan  && terraform apply


relay_ip: ## pass ip_public to inventory
	@echo "[web]" > $(AN_DIR)/inventory.ini
	@echo "35.100.20.12 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/terraform-ipssi" >> $(AN_DIR)/inventory.ini  

ansible:
	@ansible-playbook -i $(AN_DIR)/inventory.ini $(AN_DIR)/apache.yml


build: tr_plan_apply relay_ip ansible
