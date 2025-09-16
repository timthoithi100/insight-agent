# Insight-Agent Makefile
# Provides common development and deployment tasks

.PHONY: help install lint test docker-build docker-run tf-init tf-plan tf-apply tf-destroy clean

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Python environment setup
install: ## Install Python dependencies
	pip install -r requirements.txt
	pip install pytest flake8 black isort

# Code quality
lint: ## Run linting tools
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
	black --check .
	isort --check-only .

format: ## Format code with black and isort
	black .
	isort .

test: ## Run tests
	python -m pytest test_app.py -v

test-coverage: ## Run tests with coverage
	python -m pytest test_app.py --cov=main --cov-report=html --cov-report=term

# Docker operations
docker-build: ## Build Docker image locally
	docker build -t insight-agent:latest .

docker-run: ## Run Docker container locally
	docker run -p 8080:8080 insight-agent:latest

docker-test: ## Test the locally running container
	@echo "Testing container endpoints..."
	@sleep 5
	@curl -f http://localhost:8080/health || echo "Health check failed"
	@curl -f -X POST http://localhost:8080/analyze \
		-H "Content-Type: application/json" \
		-d '{"text": "Hello from local Docker test!"}' || echo "Analyze test failed"

# Terraform operations
tf-init: ## Initialize Terraform
	cd terraform && terraform init

tf-validate: ## Validate Terraform configuration
	cd terraform && terraform validate
	terraform fmt -check -recursive terraform/

tf-plan: ## Show Terraform execution plan
	@if [ ! -f terraform/terraform.tfvars ]; then \
		echo "Error: terraform/terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."; \
		exit 1; \
	fi
	cd terraform && terraform plan

tf-apply: ## Apply Terraform configuration
	@if [ ! -f terraform/terraform.tfvars ]; then \
		echo "Error: terraform/terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."; \
		exit 1; \
	fi
	cd terraform && terraform apply

tf-destroy: ## Destroy Terraform-managed infrastructure
	cd terraform && terraform destroy

tf-output: ## Show Terraform outputs
	cd terraform && terraform output

# Development workflow
dev-setup: install tf-init ## Set up development environment
	@echo "Development environment setup complete!"
	@echo "Don't forget to:"
	@echo "1. Copy terraform/terraform.tfvars.example to terraform/terraform.tfvars"
	@echo "2. Configure your GCP credentials"
	@echo "3. Update terraform.tfvars with your project settings"

dev-test: lint test docker-build ## Run all development tests

# Deployment helpers
deploy-check: ## Check deployment prerequisites
	@echo "Checking deployment prerequisites..."
	@command -v gcloud >/dev/null 2>&1 || { echo "gcloud CLI is required but not installed."; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "terraform is required but not installed."; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "docker is required but not installed."; exit 1; }
	@gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q . || { echo "No active gcloud authentication found."; exit 1; }
	@echo "✓ All deployment prerequisites are met"

# Cleanup
clean: ## Clean up temporary files and caches
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov/
	rm -rf dist/
	rm -rf build/

# Local development server
dev-server: ## Run development server locally
	python main.py

# Quick deployment (for development)
quick-deploy: dev-test deploy-check ## Quick development deployment
	@echo "Running quick deployment..."
	@echo "This will deploy the current code to your configured GCP project"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	$(MAKE) tf-apply