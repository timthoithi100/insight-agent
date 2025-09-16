# Insight-Agent: AI-Powered Text Analysis Service

A secure, scalable, and production-ready text analysis service deployed on Google Cloud Platform using Infrastructure as Code and automated CI/CD pipelines.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│  GitHub Actions │───▶│  Artifact Reg   │
│                 │    │     CI/CD       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        │
                       ┌─────────────────┐               │
                       │   Terraform     │               │
                       │  Infrastructure │               │
                       └─────────────────┘               │
                                │                        │
                                ▼                        │
┌─────────────────┐    ┌─────────────────┐               │
│   External      │───▶│   Cloud Run     │◀──────────────┘
│   Client        │    │    Service      │
│ (Authenticated) │    │ (Private Access)│
└─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Service Account│
                       │ (Least Privilege)│
                       └─────────────────┘
```

### GCP Services Used
- **Cloud Run**: Serverless container platform for hosting the FastAPI application
- **Artifact Registry**: Secure Docker image storage
- **Cloud Build**: Container image building (via GitHub Actions)
- **IAM**: Identity and access management with least-privilege service accounts
- **VPC Connector**: (Optional) For private network access

## Key Design Decisions

### Why Cloud Run?
- **Serverless**: Pay-per-request pricing with automatic scaling to zero
- **Container-native**: Full control over the runtime environment
- **Security**: Built-in HTTPS, private access controls, and service account integration
- **Scalability**: Automatic scaling based on traffic with configurable limits

### Security Implementation
- **Private Access**: Cloud Run service is configured for internal traffic only
- **Least Privilege IAM**: Dedicated service accounts with minimal required permissions
- **Non-root Container**: Application runs as non-root user inside the container
- **No Secrets in Code**: All sensitive data managed through GCP Secret Manager or environment variables

### CI/CD Pipeline Strategy
- **Multi-stage Validation**: Linting, testing, and Terraform validation before deployment
- **Immutable Infrastructure**: Complete infrastructure defined in Terraform
- **Atomic Deployments**: New container images are built and deployed atomically
- **Rollback Capability**: Easy rollback through Terraform state management

## Quick Start

### Prerequisites
- Google Cloud Platform account with billing enabled
- `gcloud` CLI installed and configured
- `terraform` >= 1.0 installed
- `docker` installed
- `python` 3.11+ installed

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd insight-agent

# Run the automated setup script
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 2. Configure GCP Authentication

```bash
# Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### 3. Configure Terraform Variables

```bash
# Copy the example configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your project details
vim terraform/terraform.tfvars
```

Required variables in `terraform.tfvars`:
```hcl
project_id = "your-gcp-project-id"
region     = "us-central1"
allow_public_access = false  # Keep false for security
```

### 4. Deploy Infrastructure

```bash
# Validate configuration
make tf-validate

# Review deployment plan
make tf-plan

# Deploy to GCP
make tf-apply
```

### 5. Set Up CI/CD (Optional)

For automated deployments, configure GitHub secrets:

- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_SA_KEY`: Service account key JSON (create via GCP Console)

## Local Development

### Running Locally

```bash
# Set up development environment
make dev-setup

# Activate virtual environment
source venv/bin/activate

# Run the application
make dev-server
# OR
python main.py
```

### Testing

```bash
# Run linting and tests
make dev-test

# Run tests only
make test

# Test with coverage
make test-coverage
```

### Docker Development

```bash
# Build container
make docker-build

# Run container locally
make docker-run

# Test the container
make docker-test
```

## API Usage

### Health Check
```bash
curl https://your-service-url/health
```

### Text Analysis
```bash
curl -X POST https://your-service-url/analyze \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -d '{"text": "I love this amazing product! It works great."}'
```

Response:
```json
{
  "original_text": "I love this amazing product! It works great.",
  "word_count": 8,
  "character_count": 44,
  "character_count_no_spaces": 36,
  "sentence_count": 2,
  "paragraph_count": 1,
  "avg_word_length": 4.75,
  "sentiment_score": "positive"
}
```

## Security Features

### Access Control
- **Private Cloud Run Service**: Only accessible via authenticated requests
- **Service Account Authentication**: Uses least-privilege service accounts
- **VPC Integration**: Optional VPC connector for network-level security

### Authentication for Private Services
```bash
# Get service URL
SERVICE_URL=$(cd terraform && terraform output -raw service_url)

# Make authenticated request
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -X POST $SERVICE_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from authenticated client!"}'
```

### Container Security
- Multi-stage Docker build for minimal image size
- Non-root user execution
- Health checks for reliability
- Resource limits to prevent abuse

## Monitoring and Observability

### Cloud Run Metrics
- Request latency and error rates
- Instance utilization and scaling events
- Container resource usage

### Logs
```bash
# View application logs
gcloud logs read --filter="resource.type=cloud_run_revision"

# Follow logs in real-time
gcloud logs tail --filter="resource.type=cloud_run_revision"
```

### Health Monitoring
- Built-in health check endpoint: `/health`
- Container-level health checks
- Automatic restart on failure

## Available Make Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make install` | Install Python dependencies |
| `make lint` | Run code linting |
| `make test` | Run tests |
| `make docker-build` | Build Docker image |
| `make tf-plan` | Show Terraform plan |
| `make tf-apply` | Apply Terraform changes |
| `make dev-setup` | Complete development setup |
| `make deploy-check` | Check deployment prerequisites |

## Customization

### Scaling Configuration
Edit `terraform/variables.tf`:
```hcl
variable "min_instances" {
  default = 0  # Scale to zero when idle
}

variable "max_instances" {
  default = 10  # Maximum concurrent instances
}
```

### Resource Limits
Edit `terraform/main.tf` in the Cloud Run configuration:
```hcl
resources {
  limits = {
    cpu    = "1"      # 1 vCPU
    memory = "1Gi"    # 1GB RAM
  }
}
```

### Adding Environment Variables
```hcl
env {
  name  = "CUSTOM_SETTING"
  value = "custom_value"
}
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   # Re-authenticate
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Permission Denied**
   ```bash
   # Check active account
   gcloud auth list
   
   # Verify project access
   gcloud projects get-iam-policy $PROJECT_ID
   ```

3. **Terraform State Issues**
   ```bash
   # Check Terraform state
   cd terraform && terraform show
   
   # Import existing resources if needed
   terraform import google_project_service.required_apis["run.googleapis.com"] $PROJECT_ID/run.googleapis.com
   ```

4. **Container Build Failures**
   ```bash
   # Test Docker build locally
   make docker-build
   
   # Check build logs
   gcloud builds log --region=$REGION
   ```

### Getting Service URL
```bash
# From Terraform output
cd terraform && terraform output service_url

# From gcloud
gcloud run services list --platform=managed
```

### Accessing Private Service
```bash
# Use gcloud proxy for testing
gcloud run services proxy SERVICE_NAME --port=8080 --region=$REGION &
curl http://localhost:8080/analyze -X POST -H "Content-Type: application/json" -d '{"text": "test"}'
```

## Cleanup

### Destroy Infrastructure
```bash
# Remove all GCP resources
make tf-destroy

# Clean local files
make clean
```

### Remove Docker Images
```bash
# Remove local images
docker rmi insight-agent:latest

# Clean up Artifact Registry (optional)
gcloud artifacts repositories delete REPOSITORY_NAME --location=$REGION
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and test: `make dev-test`
4. Commit changes: `git commit -am 'Add feature'`
5. Push to branch: `git push origin feature-name`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review GCP documentation for Cloud Run and Terraform
3. Check GitHub Issues for known problems
4. Contact the development team

---

**Built with care for reliable, scalable text analysis on Google Cloud Platform**