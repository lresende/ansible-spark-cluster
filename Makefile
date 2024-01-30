.PHONY: help setup deploy destroy

help:
	@echo "Available targets:"
	@echo " setup         : Setup infrastructure dependencies"
	@echo " deploy        : Deploy infrastructure using Terraform"
	@echo " destroy       : Destroy infrastructure"

setup:
	@echo "\033[1;94mSetting up infrastructure dependencies...\033[0m"
	cat /etc/lsb-release
	@echo "Checking distribution..."
	@if grep -qiE 'centos' /etc/os-release; then \
		echo "CentOS distribution detected\033[1;93m"; \
		curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
		sudo rpm -i epel-release-latest-7.noarch.rpm; \
		sudo yum update -y; \
		sudo yum install -y  ansible; \
		echo "\033[1;94mAnsible Installed!\033[1;93m"; \
		sudo yum install -y yum-utils; \
		sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo; \
		sudo yum -y install terraform; \
		echo "\033[1;94mTerraform Installed!\033[1;93m"; \
	else \
		echo "Distribution is not CentOS\033[1;93m"; \
		sudo apt -y install ansible; \
		echo "\033[1;94mAnsible Installed!\033[1;93m"; \
		sudo apt -y install terraform; \
		echo "\033[1;94mTerraform Installed!\033[1;93m"; \
	fi
	@echo "\033[1;92mInfrastructure setup complete"

deploy:
	@echo "Deploying infrastructure..."
	cd terraform && terraform init && terraform apply
	@echo "Infrastructure deployed"
	@echo "Configuring infrastructure using Ansible..."
	cd ansible && ansible-playbook deploy.yml -i ../terraform/ansible_hosts
	@echo "Infrastructure configuration complete"

destroy:
	@echo "Destroying infrastructure..."
	cd terraform && terraform destroy
	@echo "Infrastructure destroyed"