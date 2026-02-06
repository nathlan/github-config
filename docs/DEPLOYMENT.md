# Deployment Guide - GitHub Terraform Infrastructure

This guide provides step-by-step instructions for deploying and managing GitHub infrastructure using the Terraform CI/CD pipeline.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Deployment Process](#deployment-process)
5. [Workflow Triggers](#workflow-triggers)
6. [Monitoring & Verification](#monitoring--verification)
7. [Configuration Variables](#configuration-variables)

---

## Overview

The GitHub Terraform workflow (`github-terraform.yml`) automates the deployment and management of GitHub resources using infrastructure as code. It provides:

- **Automated validation** - Format checks, validation, and linting
- **Security scanning** - Checkov security analysis
- **Safe deployments** - Plan review before apply
- **Drift detection** - Daily automated checks
- **Approval gates** - Manual approval required for production changes

### Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Validate   │───▶│   Security   │───▶│    Plan     │───▶│    Apply    │
│             │    │   Scanning   │    │  (Review)   │    │  (Approval) │
└─────────────┘    └──────────────┘    └─────────────┘    └─────────────┘
     ↓                    ↓                   ↓                   ↓
   TFLint            Checkov              Artifact           Production
  Terraform         SARIF Upload         Upload 30d         github-admin
                                                            Environment
```

---

## Prerequisites

### Required Tools

- **GitHub Account** with admin access to target organization (`nathlan`)
- **GitHub App** configured with appropriate permissions (see [TOKEN_PERMISSIONS.md](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md))
- **Repository Access** to `nathlan/github-config`

### Required Secrets & Variables

Before running the workflow, ensure the following are configured in repository settings:

#### Repository Variables

| Variable Name | Type | Description | How to Find |
|--------------|------|-------------|-------------|
| `GH_CONFIG_APP_ID` | Variable | GitHub App ID (numeric) | GitHub App settings → General → App ID |
| `GH_APP_INSTALLATION_ID` | Variable | Installation ID for organization | GitHub App → Install App → Select org → URL contains installation ID |

#### Repository Secrets

| Secret Name | Type | Description | Format |
|------------|------|-------------|--------|
| `GH_CONFIG_PRIVATE_KEY` | Secret | GitHub App private key | Full PEM content including headers |

#### Environment Configuration

Create the following environments in repository settings:

1. **`github-admin-plan`** (optional approval)
   - Used for: Planning stage
   - Reviewers: Optional
   - Purpose: Review planned changes before apply

2. **`github-admin`** (required approval)
   - Used for: Production deployments
   - Reviewers: **Required** - Add designated approvers
   - Purpose: Manual approval gate for infrastructure changes
   - Environment URL: `https://github.com/nathlan`

---

## Initial Setup

### Step 1: Configure GitHub App

1. **Create GitHub App** (if not already created):
   ```bash
   # Navigate to GitHub Organization Settings
   # Settings → Developer settings → GitHub Apps → New GitHub App
   ```

2. **Required Permissions**:
   - Repository Administration: Read & Write
   - Repository Contents: Read & Write
   - Repository Metadata: Read
   - See [TOKEN_PERMISSIONS.md](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md) for complete list

3. **Generate Private Key**:
   - In GitHub App settings → General → Private keys → Generate a private key
   - Download the `.pem` file
   - Copy entire content including `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`

4. **Install App to Organization**:
   - GitHub App → Install App → Select `nathlan` organization
   - Note the installation ID from URL: `https://github.com/organizations/nathlan/settings/installations/XXXXXX`

### Step 2: Configure Repository Secrets

1. **Navigate to Repository Settings**:
   ```
   GitHub → nathlan/github-config → Settings → Secrets and variables → Actions
   ```

2. **Add Variables**:
   - Click "Variables" tab
   - Add `GH_CONFIG_APP_ID`: Your GitHub App ID (e.g., `123456`)
   - Add `GH_APP_INSTALLATION_ID`: Your installation ID (e.g., `789012`)

3. **Add Secrets**:
   - Click "Secrets" tab
   - Add `GH_CONFIG_PRIVATE_KEY`: Paste entire PEM file content

### Step 3: Create Environments

1. **Navigate to Environments**:
   ```
   GitHub → nathlan/github-config → Settings → Environments
   ```

2. **Create `github-admin-plan` Environment**:
   - Name: `github-admin-plan`
   - Protection rules: (Optional) Add reviewers for plan review
   - Save

3. **Create `github-admin` Environment**:
   - Name: `github-admin`
   - Protection rules:
     - ✅ Required reviewers: Add yourself and/or team members
     - ⏱️ Wait timer: 0 minutes (or add delay if needed)
   - Environment secrets: None needed
   - Save

### Step 4: Verify Configuration

Run the verification checklist:

```bash
# Clone repository
git clone https://github.com/nathlan/github-config.git
cd github-config/terraform-configs/new-repository

# Verify Terraform configuration
terraform init
terraform validate

# Verify formatting
terraform fmt -check -recursive

# Test plan locally (optional - requires local credentials)
export GITHUB_APP_ID="your-app-id"
export GITHUB_APP_INSTALLATION_ID="your-installation-id"
export GITHUB_APP_PEM_FILE="path-to-private-key.pem"

terraform plan -var="github_organization=nathlan"
```

---

## Deployment Process

### Standard Deployment Flow

#### 1. Create Feature Branch

```bash
git checkout -b feature/update-github-config
```

#### 2. Make Configuration Changes

Edit Terraform files in `terraform-configs/new-repository/`:

```hcl
# Example: Change repository name in terraform.tfvars
repository_name = "my-new-repo"
repository_description = "My awesome repository"
repository_visibility = "private"
```

#### 3. Commit and Push

```bash
git add terraform-configs/new-repository/
git commit -m "feat: add new repository configuration"
git push origin feature/update-github-config
```

#### 4. Create Pull Request

- Navigate to GitHub repository
- Click "New Pull Request"
- Select `feature/update-github-config` → `main`
- Review automated workflow results:
  - ✅ Validation passes
  - ✅ Security scan passes
  - 📝 Plan output in PR comment

#### 5. Review Plan Output

The workflow will automatically comment on the PR with:
- Terraform plan output
- Resources to be added/changed/destroyed
- Validation and security scan results

**Example PR Comment**:
```
#### Terraform Plan 📝 Changes detected

<details><summary>Show Plan</summary>

Terraform will perform the following actions:

  # github_repository.repo will be created
  + resource "github_repository" "repo" {
      + name = "my-new-repo"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
</details>
```

#### 6. Approve and Merge

- **Review**: Ensure plan output matches expectations
- **Security**: Verify no security issues reported
- **Approve**: Get required PR approvals
- **Merge**: Merge PR to `main` branch

#### 7. Production Deployment

After merge to `main`:

1. Workflow automatically triggers
2. Validation and security scans run again
3. Plan is regenerated
4. **Manual approval required** at `github-admin` environment
5. Designated approver reviews and approves
6. Apply runs and creates/updates resources
7. Deployment summary created

---

## Workflow Triggers

### Automatic Triggers

| Trigger | Condition | Jobs Run | Apply? |
|---------|-----------|----------|--------|
| **Pull Request** | Any changes to `terraform-configs/new-repository/**` or workflow file | validate → security → plan | ❌ No |
| **Push to Main** | Merged PR or direct push | validate → security → plan → **apply** | ✅ Yes (with approval) |
| **Schedule** | Daily at 8 AM UTC | validate → security → plan → apply (drift check) | ⚠️ Conditional |

### Manual Triggers

| Trigger | Purpose | Usage |
|---------|---------|-------|
| **workflow_dispatch** | Manual deployment or testing | Actions tab → Select workflow → Run workflow |
| Choose action: `plan` | Generate plan without applying | Safe for testing |
| Choose action: `apply` | Apply changes manually | Requires approval |

### Drift Detection

**Schedule**: Daily at 8:00 AM UTC

**Purpose**: Detect manual changes made outside Terraform

**Process**:
1. Workflow runs `terraform plan`
2. If differences detected (exit code 2):
   - ⚠️ Drift detected
   - Issue created automatically with details
   - Notification sent to watchers
3. If no differences (exit code 0):
   - ✅ No drift detected
   - Summary logged, no issue created

**Responding to Drift**:
- Review issue created by workflow
- Investigate what changed and why
- Options:
  1. Update Terraform to match manual changes (codify)
  2. Revert manual changes by reapplying Terraform
  3. Document and accept drift (if intentional)

---

## Monitoring & Verification

### Successful Deployment

✅ **Indicators**:
- All workflow jobs show green checkmarks
- PR has plan comment with expected changes
- Apply job completes successfully
- Deployment summary generated
- Resources visible in GitHub organization

### Verification Steps

After deployment, verify resources:

```bash
# Using gh CLI
gh repo view nathlan/my-new-repo

# Or via web UI
open https://github.com/nathlan/my-new-repo
```

**Checklist**:
- [ ] Repository exists with correct name
- [ ] Visibility matches configuration (private/public)
- [ ] Branch protection rules active on `main`
- [ ] GitHub Actions enabled
- [ ] Required approvals configured
- [ ] Topics applied to repository

### Monitoring Locations

| Resource | Location | Purpose |
|----------|----------|---------|
| **Workflow Runs** | Actions tab | View execution history |
| **Security Alerts** | Security tab → Code scanning | Checkov findings |
| **Drift Issues** | Issues tab → `drift-detection` label | Automated drift reports |
| **Environment Deployments** | Environments tab | Approval history |
| **Terraform State** | Local `.terraform/` (not committed) | State tracking |

---

## Configuration Variables

### Terraform Variables

Located in `terraform-configs/new-repository/variables.tf`:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `github_organization` | string | (required) | Target GitHub organization |
| `repository_name` | string | `example-repo` | Name of repository to create |
| `repository_description` | string | `Repository managed by Terraform` | Repo description |
| `repository_visibility` | string | `private` | Visibility: public/private/internal |
| `copilot_firewall_allowlist` | list(string) | [terraform registries] | Copilot firewall domains |
| `branch_protection_required_approving_review_count` | number | `1` | Required PR approvals |
| `enable_copilot_pr_from_actions` | bool | `true` | Allow Copilot to create PRs |

### Customization

Create `terraform.tfvars` (git-ignored) for local overrides:

```hcl
# terraform-configs/new-repository/terraform.tfvars
repository_name        = "my-custom-repo"
repository_description = "Production service repository"
repository_visibility  = "public"

# Increase security
branch_protection_required_approving_review_count = 2

# Add custom firewall domains
copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io",
  "custom-domain.example.com"
]
```

**Note**: `terraform.tfvars` is ignored by git for security. Use workflow inputs or commit to a separate encrypted store for CI/CD.

---

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

For rollback procedures, see [ROLLBACK.md](./ROLLBACK.md).

---

## Security Best Practices

### Secrets Management

✅ **Do**:
- Store GitHub App private key as repository secret
- Use separate GitHub Apps for dev/staging/prod
- Rotate private keys periodically
- Review GitHub App permissions regularly

❌ **Don't**:
- Commit secrets to git
- Share private keys in chat/email
- Use personal access tokens for automation
- Grant excessive permissions to GitHub App

### Approval Process

✅ **Do**:
- Require manual approval for production deployments
- Review plan output before approving
- Verify resource changes match expectations
- Document approval decisions

❌ **Don't**:
- Auto-approve without review
- Skip security scan results
- Ignore drift detection issues
- Bypass approval process

---

## Next Steps

- [ ] Complete initial setup
- [ ] Configure environments with approvers
- [ ] Test workflow with manual trigger
- [ ] Deploy first resource
- [ ] Set up drift detection monitoring
- [ ] Review security scan results
- [ ] Document any custom configurations

---

**Need Help?**
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [Rollback Procedures](./ROLLBACK.md)
- [Token Permissions Reference](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md)
- [Terraform GitHub Provider Docs](https://registry.terraform.io/providers/integrations/github/latest/docs)
