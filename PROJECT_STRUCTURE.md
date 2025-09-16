# Insight-Agent Project Structure

This document provides a complete overview of the project structure and the purpose of each file and directory.

```
insight-agent/
├── README.md                           # Main project documentation
├── LICENSE                             # MIT license file
├── PROJECT_STRUCTURE.md                # This file - project structure overview
├── Makefile                            # Development and deployment automation
├── requirements.txt                    # Python dependencies
├── Dockerfile                          # Container definition
├── .dockerignore                       # Files to exclude from Docker build
├── .gitignore                          # Files to exclude from git
│
├── main.py                             # FastAPI application entry point
├── test_app.py                         # Comprehensive test suite
│
├── .github/                            # GitHub-specific configuration
│   └── workflows/                      # CI/CD pipeline definitions
│       └── deploy.yml                  # Main deployment workflow
│
├── terraform/                          # Infrastructure as Code
│   ├── main.tf                         # Main Terraform configuration
│   ├── variables.tf                    # Input variable definitions
│   ├── outputs.tf                      # Output value definitions
│   └── terraform.tfvars.example        # Example configuration file
│
├── scripts/                            # Utility scripts
│   └── setup.sh                        # Automated environment setup
│
└── docs/                               # Additional documentation (optional)
    ├── API.md                          # API documentation
    ├── DEPLOYMENT.md                   # Deployment guide
    └── SECURITY.md                     # Security considerations
```

## File Descriptions

### Root Level Files

| File | Purpose | Key Features |
|------|---------|--------------|
| `README.md` | Main project documentation | Architecture overview, setup instructions, API usage |
| `LICENSE` | MIT license terms | Open source license |
| `Makefile` | Development automation | Common tasks: test, build, deploy, clean |
| `requirements.txt` | Python dependencies | FastAPI, uvicorn, pydantic, gunicorn |
| `Dockerfile` | Container definition | Multi-stage build, security best practices |
| `.dockerignore` | Docker build exclusions | Excludes unnecessary files from image |
| `.gitignore` | Git exclusions | Python cache, environment files, Terraform state |

### Application Code

| File | Purpose | Key Features |
|------|---------|--------------|
| `main.py` | FastAPI application | `/analyze` endpoint, text analysis logic, health checks |
| `test_app.py` | Test suite | Unit tests, integration tests, edge cases |

### Infrastructure (terraform/)

| File | Purpose | Key Features |
|------|---------|--------------|
| `main.tf` | Core infrastructure | Cloud Run, Artifact Registry, IAM, APIs |
| `variables.tf` | Configuration inputs | Project ID, region, scaling, security settings |
| `outputs.tf` | Resource outputs | Service URL, repository info, service accounts |
| `terraform.tfvars.example` | Configuration template | Example values for all variables |

### CI/CD (.github/workflows/)

| File | Purpose | Key Features |
|------|---------|--------------|
| `deploy.yml` | GitHub Actions workflow | Lint, test, build, deploy pipeline |

### Scripts (scripts/)

| File | Purpose | Key Features |
|------|---------|--------------|
| `setup.sh` | Environment setup | Dependency checks, Python env, Terraform init |

## Configuration Files

### Application Configuration
- **Port**: 8080 (configurable via `PORT` environment variable)
- **Environment**: Production (configurable via `ENVIRONMENT` variable)
- **Logging**: Structured JSON logging to Cloud Logging

### Infrastructure Configuration
- **Region**: us-central1 (configurable)
- **Scaling**: 0-10 instances (configurable)
- **Access**: Private by default (configurable)
- **Resources**: 1 vCPU, 1GB RAM (configurable)

### Security Configuration
- **Container**: Non-root user, health checks
- **IAM**: Least-privilege service accounts
- **Network**: Private ingress, optional VPC connector

## Getting Started Checklist

### 1. Prerequisites
- [ ] GCP account with billing enabled
- [ ] Required CLI tools installed (gcloud, terraform, docker)
- [ ] Python 3.11+ installed

### 2. Initial Setup
- [ ] Clone repository
- [ ] Run `./scripts/setup.sh`
- [ ] Configure GCP authentication
- [ ] Copy and edit `terraform/terraform.tfvars`

### 3. Deployment
- [ ] Validate configuration: `make tf-validate`
- [ ] Review deployment plan: `make tf-plan`
- [ ] Deploy infrastructure: `make tf-apply`

### 4. CI/CD (Optional)
- [ ] Set up GitHub repository secrets
- [ ] Push to main branch to trigger deployment

## Key Design Patterns

### 1. Infrastructure as Code
- All infrastructure defined in Terraform
- Version-controlled infrastructure changes
- Repeatable deployments across environments

### 2. Containerized Application
- Docker multi-stage build for optimization
- Security-hardened container (non-root user)
- Health checks for reliability

### 3. Secure by Default
- Private Cloud Run service
- Least-privilege IAM roles
- No hardcoded secrets

### 4. Automated Testing
- Unit tests for application logic
- Integration tests for API endpoints
- Infrastructure validation in CI/CD

### 5. Observability
- Structured logging
- Health check endpoints
- Cloud Run native monitoring

## Scalability Considerations

### Horizontal Scaling
- Cloud Run automatic scaling (0-10 instances)
- Pay-per-request pricing model
- Concurrent request handling

### Performance Optimization
- Lightweight container image
- Efficient Python application
- Resource limits to prevent resource exhaustion

### Cost Optimization
- Scale-to-zero capability
- Shared nothing architecture
- Resource-based pricing

## Security Architecture

### Defense in Depth
1. **Network Level**: Private ingress, optional VPC
2. **Identity Level**: Service account authentication
3. **Application Level**: Input validation, rate limiting
4. **Container Level**: Non-root user, minimal image

### Compliance Considerations
- GDPR: No persistent data storage
- SOC 2: Audit logging, access controls
- PCI DSS: Network segmentation, encryption

## Testing Strategy

### Test Pyramid
1. **Unit Tests**: Core business logic (test_app.py)
2. **Integration Tests**: API endpoint testing
3. **Contract Tests**: API schema validation
4. **End-to-End Tests**: Full deployment validation

### Continuous Testing
- Pre-commit hooks for code quality
- CI/CD pipeline testing
- Production health monitoring

## Monitoring and Alerting

### Built-in Monitoring
- Cloud Run request metrics
- Error rate and latency tracking
- Container resource utilization

### Custom Monitoring
- Application-specific metrics
- Business logic monitoring
- Performance trend analysis

## Development Workflow

### Local Development
1. Set up environment: `make dev-setup`
2. Run tests: `make test`
3. Start dev server: `make dev-server`
4. Test locally: `make docker-test`

### Production Deployment
1. Create feature branch
2. Make changes and test
3. Push to GitHub
4. Automated CI/CD deployment
5. Monitor deployment health

This structure ensures maintainability, security, and scalability while following cloud-native best practices.