#!/bin/bash
set -e

# Setup script for Insight-Agent
# This script helps set up the development and deployment environment

echo "🚀 Setting up Insight-Agent environment..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
        missing_deps+=("pip")
    fi
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_deps+=("terraform")
    fi
    
    if ! command -v gcloud &> /dev/null; then
        missing_deps+=("gcloud")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and run this script again."
        echo ""
        echo "Installation instructions:"
        echo "- Python 3: https://www.python.org/downloads/"
        echo "- Docker: https://docs.docker.com/get-docker/"
        echo "- Terraform: https://developer.hashicorp.com/terraform/downloads"
        echo "- Google Cloud CLI: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Set up Python virtual environment
setup_python_env() {
    print_status "Setting up Python environment..."
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        print_success "Created Python virtual environment"
    else
        print_warning "Virtual environment already exists"
    fi
    
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    pip install pytest flake8 black isort
    
    print_success "Python environment set up successfully"
}

# Set up Terraform configuration
setup_terraform() {
    print_status "Setting up Terraform configuration..."
    
    cd terraform
    
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_warning "Created terraform.tfvars from example. Please edit it with your project details."
        else
            print_error "terraform.tfvars.example not found"
            exit 1
        fi
    else
        print_warning "terraform.tfvars already exists"
    fi
    
    terraform init
    print_success "Terraform initialized"
    
    cd ..
}

# Validate Terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    cd terraform
    terraform validate
    terraform fmt -check || {
        print_warning "Terraform files need formatting. Running terraform fmt..."
        terraform fmt
    }
    cd ..
    
    print_success "Terraform configuration is valid"
}

# Set up GCP authentication
setup_gcp_auth() {
    print_status "Checking GCP authentication..."
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_warning "No active GCP authentication found"
        echo "Please run: gcloud auth login"
        echo "And then: gcloud auth application-default login"
        return 1
    fi
    
    print_success "GCP authentication is active"
    
    # Check if a project is set
    current_project=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -z "$current_project" ]; then
        print_warning "No default GCP project set"
        echo "Please run: gcloud config set project YOUR_PROJECT_ID"
        return 1
    fi
    
    print_success "GCP project set to: $current_project"
}

# Run basic tests
run_tests() {
    print_status "Running basic tests..."
    
    source venv/bin/activate
    python -m pytest test_app.py -v
    
    print_success "All tests passed"
}

# Main setup flow
main() {
    echo "================================================"
    echo "       Insight-Agent Environment Setup"
    echo "================================================"
    echo ""
    
    check_dependencies
    setup_python_env
    setup_terraform
    validate_terraform
    
    echo ""
    echo "================================================"
    echo "              Setup Summary"
    echo "================================================"
    
    print_success "✓ Dependencies checked"
    print_success "✓ Python environment created"
    print_success "✓ Terraform initialized"
    print_success "✓ Configuration validated"
    
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Configure GCP authentication:"
    echo "   gcloud auth login"
    echo "   gcloud auth application-default login"
    echo "   gcloud config set project YOUR_PROJECT_ID"
    echo ""
    echo "2. Edit terraform/terraform.tfvars with your project details"
    echo ""
    echo "3. Set up GitHub secrets for CI/CD:"
    echo "   - GCP_PROJECT_ID: Your GCP project ID"
    echo "   - GCP_SA_KEY: Service account key JSON"
    echo ""
    echo "4. Test your setup:"
    echo "   make dev-test"
    echo ""
    echo "5. Deploy to GCP:"
    echo "   make tf-plan"
    echo "   make tf-apply"
    echo ""
    
    # Try to set up GCP auth
    if setup_gcp_auth; then
        echo ""
        print_status "Running tests..."
        if run_tests; then
            echo ""
            print_success "🎉 Setup completed successfully! You're ready to deploy."
        else
            print_warning "Setup completed but tests failed. Please check the issues above."
        fi
    else
        echo ""
        print_warning "Setup completed but GCP authentication needs configuration."
        print_warning "Please follow the steps above to complete the setup."
    fi
}

# Run main function
main "$@"