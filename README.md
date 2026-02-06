# GitHub Configuration Management

This repository manages GitHub organization configuration using Terraform and Infrastructure as Code principles.

## Repository Structure

```
github-config/
├── .github/workflows/      # CI/CD pipelines
│   └── github-terraform.yml
├── .handover/              # Agent handoff documentation
│   ├── AGENT_INSTRUCTIONS_IMPROVEMENTS.md
│   ├── CICD_WORKFLOW_HANDOFF.md
│   └── HANDOFF_TO_WORKFLOW_AGENT.md
├── terraform/              # Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── README.md          # Detailed Terraform documentation
└── README.md              # This file
```

## What This Repository Manages

This Terraform configuration creates and manages multiple GitHub repositories in your organization with:

- **Repository Configuration**: Multiple repositories with customizable settings
- **Branch Protection**: Rulesets for `main` branch with required reviews
- **GitHub Actions**: Permissions and workflow configurations
- **Copilot Agent Firewall**: Network allowlist for Copilot agents
- **Automated Workflows**: PR creation permissions for Actions

## Quick Start

### Prerequisites

1. **GitHub App** with required permissions (see `terraform/TOKEN_PERMISSIONS.md`)
2. **Terraform** >= 1.9.0
3. **Environment Variables**:
   - `GH_CONFIG_APP_ID` (GitHub App ID)
   - `GH_CONFIG_INSTALLATION_ID` (Installation ID)
   - `GH_CONFIG_PRIVATE_KEY` (Private key PEM content)

### Usage

1. **Configure your repositories** in `terraform/terraform.tfvars`:

```hcl
github_organization = "your-org"

repositories = [
  {
    name        = "repo-1"
    description = "First repository"
    visibility  = "private"
    branch_protection_required_approving_review_count = 1
  },
  # Add more repositories...
]
```

2. **Run via CI/CD**:
   - Push changes to this repository
   - GitHub Actions workflow will run Terraform
   - Review plan in PR comments
   - Approve to apply changes

3. **Or run manually**:

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## Documentation

- **Terraform Configuration**: See `terraform/README.md` for detailed usage
- **Authentication Setup**: See `terraform/TOKEN_PERMISSIONS.md` for GitHub App setup
- **CI/CD Workflow**: See `.github/workflows/github-terraform.yml` for pipeline details
- **Agent Handoff**: See `.handover/` for agent documentation and instructions

## CI/CD Pipeline

The repository includes an automated CI/CD pipeline that:

1. **Validates** Terraform configuration on every PR
2. **Security Scans** with Checkov
3. **Plans** changes with detailed output
4. **Applies** after manual approval
5. **Detects Drift** daily at 8 AM UTC

## Security

- All secrets managed via GitHub App authentication
- No hardcoded credentials in code
- Security scanning on every change
- Manual approval required for production changes

## Contributing

1. Create a feature branch
2. Make changes to `terraform/` files
3. Open a PR
4. Review the Terraform plan in PR comments
5. Approve and merge after review

## Support

For issues or questions, see:
- Terraform documentation in `terraform/README.md`
- Troubleshooting in CI/CD workflow comments
- Agent handoff documentation in `.handover/`

---

**Managed by**: Terraform + GitHub Actions  
**Last Updated**: 2026-02-06
