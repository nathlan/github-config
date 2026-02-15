# Shared Assets Repository - Terraform Configuration

This Terraform module creates and manages the `shared-assets` GitHub repository with common organizational settings.

## Overview

This module provisions a simple GitHub repository initialized with a README file. Unlike ALZ workload repositories, this repository does NOT use the `alz-workload-template` and is designed for storing shared assets and resources.

## Resources Managed

This configuration creates and manages the following GitHub resources:

- **Repository**: `shared-assets` repository with README initialization
- **Actions Permissions**: Enables GitHub Actions with all actions allowed
- **Actions Variable**: Copilot agent firewall allowlist (optional)
- **Workflow Permissions**: Read-only default with PR creation enabled
- **Branch Protection**: Main branch protection with PR requirements

## Common Settings Applied

### Repository Features
- Issues: ✅ Enabled
- Projects: ✅ Enabled  
- Wiki: ✅ Enabled
- Discussions: ❌ Disabled

### Merge Settings
- Allow merge commits: ✅ Yes
- Allow squash merging: ✅ Yes
- Allow rebase merging: ✅ Yes
- Auto-merge: ✅ Enabled
- Delete branch on merge: ✅ Yes

### Security
- Vulnerability alerts: ✅ Enabled

### Branch Protection (Main Branch)
- Prevent deletion: ✅ Yes
- Prevent force pushes: ✅ Yes
- Require pull requests: ✅ Yes (configurable review count)
- Dismiss stale reviews: ✅ Yes
- Repository admins can bypass: ✅ Yes (via PR)

## Prerequisites

### Required Permissions

The GitHub App or Personal Access Token must have the following permissions:

- **Repository permissions:**
  - Administration: Read and write
  - Actions: Read and write (for Copilot firewall variable)
  - Metadata: Read-only

- **Organization permissions:**
  - Administration: Read and write (if creating in an organization)

### Authentication

This module supports two authentication methods:

#### GitHub App (Recommended)

Set the following environment variables:
```bash
export GITHUB_APP_ID="your-app-id"
export GITHUB_APP_INSTALLATION_ID="your-installation-id"
export GITHUB_APP_PEM_FILE="path/to/private-key.pem"
# Or provide PEM content directly:
export GITHUB_APP_PEM_FILE="-----BEGIN RSA PRIVATE KEY-----\n..."
```

#### Personal Access Token

Alternatively, use a PAT (requires provider configuration change):
```bash
export GITHUB_TOKEN="ghp_your_token_here"
```

## Usage

### Basic Usage

```hcl
# Deploy with default values
terraform init
terraform plan
terraform apply
```

### Custom Configuration

```hcl
# terraform.tfvars
repository_name        = "shared-assets"
repository_description = "Shared assets and resources"
repository_visibility  = "public"

branch_protection_required_approving_review_count = 1

copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io"
]

enable_copilot_pr_from_actions    = true
manage_copilot_firewall_variable  = true
```

### Variable Overrides

You can override variables via command line:

```bash
terraform apply \
  -var="repository_name=shared-assets" \
  -var="repository_visibility=internal" \
  -var="branch_protection_required_approving_review_count=2"
```

## Validation

### Initialize and Validate

```bash
cd terraform/
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

### Dry-Run Plan

```bash
terraform plan -var="github_owner=nathlan"
```

This performs a dry-run to show what changes would be made without actually creating resources.

## Security Considerations

### 🟢 Risk Level: Low

This configuration creates a new repository with standard security settings. No destructive operations are performed.

### Security Best Practices

- ✅ No hardcoded secrets (uses environment variables)
- ✅ Vulnerability alerts enabled
- ✅ Branch protection enforced
- ✅ Read-only default workflow permissions
- ✅ PR review requirements

### Permissions Required

- Repository creation in the organization
- Configuration of repository settings
- Management of Actions permissions (optional, for Copilot variable)

### Sensitive Variables

The following variables are marked as sensitive and will not appear in logs:
- `github_app_id`
- `github_app_installation_id`
- `github_app_pem_file`

## State Management

### Local State (Default)

By default, Terraform stores state locally in `terraform.tfstate`. This file is gitignored.

**⚠️ Important:** Do not commit the state file as it may contain sensitive data.

### Remote State (Recommended for Teams)

For team environments, use remote state:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "github-shared-assets.tfstate"
  }
}
```

## Outputs

After applying, the following outputs are available:

- `repository_name`: Name of the created repository
- `repository_full_name`: Full name (owner/repo)
- `repository_url`: Web URL to the repository
- `repository_ssh_clone_url`: SSH clone URL
- `repository_http_clone_url`: HTTPS clone URL
- `repository_id`: Numeric repository ID
- `repository_node_id`: GraphQL node ID

View outputs:
```bash
terraform output
```

## Troubleshooting

### Common Errors

**"403 Resource not accessible by integration"**
- The GitHub App lacks "Actions: Read and write" permission
- Solution: Set `manage_copilot_firewall_variable = false` in your variables

**"Repository already exists"**
- The repository name is already in use
- Solution: Choose a different name or import the existing repository

**"401 Unauthorized"**
- Authentication credentials are missing or invalid
- Solution: Verify your GITHUB_APP_* or GITHUB_TOKEN environment variables

**"Resource not found"**
- The organization or resource doesn't exist
- Solution: Verify the `github_owner` variable is correct

## Maintenance

### Updating the Repository

To update repository settings, modify the appropriate variables and run:

```bash
terraform plan  # Review changes
terraform apply # Apply changes
```

### Importing Existing Repository

If the repository already exists and you want to manage it with Terraform:

```bash
terraform import github_repository.shared_assets shared-assets
```

## References

- [GitHub Terraform Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [HashiCorp Module Structure Guidelines](https://developer.hashicorp.com/terraform/language/modules/develop/structure)
- [GitHub App Authentication](https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review GitHub provider documentation
3. Open an issue in the repository

---

**Generated by**: GitHub Configuration Agent  
**Date**: 2026-02-15  
**Terraform Version**: >= 1.9.0  
**Provider Version**: integrations/github ~> 6.0
