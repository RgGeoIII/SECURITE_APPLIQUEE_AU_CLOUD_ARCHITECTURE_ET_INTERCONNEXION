TF_DIR := infra/terraform
AN_DIR := infra/ansible
INFO_COLOR := \033[36;1m
NO_COLOR    := \033[0m
BASTION_IP  := $(shell cd $(TF_DIR) && terraform output -raw bastion_public_ip 2>/dev/null)

.PHONY: help tr_fmt tr_validate tr_plan_apply tr_output_relay_ip play build
.DEFAULT_GOAL := help

help: ## show this help
	@grep -E "^[a-zA-Z_-]+.*: ## .*$$" $(MAKEFILE_LIST) | sort \
		| awk 'BEGIN {FS=": ## "}{ printf "$(INFO_COLOR)%-20s$(NO_COLOR)%s\n", $$1, $$2}'

tr_fmt: ## format terraform configs
	@cd $(TF_DIR) && terraform fmt

tr_validate: tr_fmt ## validate terraform configs
	@cd $(TF_DIR) && terraform validate

tr_plan_apply: tr_validate ## plan and apply terraform
	@cd $(TF_DIR) && terraform plan && terraform apply

tr_output_relay_ip: ## write EC2 public IP to ansible inventory
	@echo "[web]" > $(AN_DIR)/inventory.ini
	@echo "$(BASTION_IP) ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cle-xavier.pem ansible_ssh_extra_args='-o StrictHostKeyChecking=no'" \
		>> $(AN_DIR)/inventory.ini

play: ## run the ansible playbook
	@/c/Windows/System32/wsl.exe ansible-playbook -i $(AN_DIR)/inventory.ini $(AN_DIR)/apache.yml

build: tr_plan_apply tr_output_relay_ip play ## full deploy (tf + inventory + playbook)