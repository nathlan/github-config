# Troubleshooting Guide - GitHub Terraform Infrastructure

This guide covers common issues, error messages, and solutions when working with the GitHub Terraform CI/CD workflow.

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Authentication Issues](#authentication-issues)
3. [Workflow Failures](#workflow-failures)
4. [Terraform Errors](#terraform-errors)
5. [Security Scan Issues](#security-scan-issues)
6. [Drift Detection Issues](#drift-detection-issues)
7. [Environment & Approval Issues](#environment--approval-issues)
8. [Resource-Specific Issues](#resource-specific-issues)
9. [Debug Mode](#debug-mode)

---

## Quick Diagnostics

### Health Check Checklist

Run through this checklist when encountering issues:

```bash
# 1. Check workflow status
gh run list --workflow=github-terraform.yml --limit 5

# 2. View detailed logs
gh run view <run-id> --log-failed

# 3. Check repository secrets/variables
gh variable list
gh secret list

# 4. Verify Terraform configuration locally
cd terraform-configs/new-repository
terraform init -backend=false
terraform validate
terraform fmt -check -recursive

# 5. Check GitHub App installation
gh api /orgs/nathlan/installations
```

### Common Symptoms & Quick Fixes

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| ❌ Init fails | Missing credentials | Check `GH_CONFIG_APP_ID`, `GH_APP_INSTALLATION_ID`, `GH_CONFIG_PRIVATE_KEY` |
| ❌ Plan fails with 401 | Invalid/expired token | Regenerate GitHub App private key |
| ❌ Apply blocked | No approval | Approve in environment protection |
| ⚠️ Drift detected | Manual changes | Review drift and update Terraform or reapply |
| ❌ Checkov fails | Security violation | Review Checkov output, fix issues or add skip |
| ❌ TFLint fails | Code quality issue | Fix linting errors in Terraform files |

---

## Authentication Issues

### Issue 1: "Error: Invalid GitHub App credentials"

**Symptoms**:
```
Error: failed to configure the GitHub Provider: failed to authenticate with GitHub app
Error: invalid JWT: JWT is expired
```

**Causes**:
- GitHub App private key expired
- Incorrect App ID or Installation ID
- Private key format incorrect (missing headers)
- Clock skew between runner and GitHub

**Solutions**:

#### A. Verify GitHub App Configuration

```bash
# Check if variables are set
gh variable list | grep GH_CONFIG_APP_ID
gh variable list | grep GH_APP_INSTALLATION_ID
gh secret list | grep GH_CONFIG_PRIVATE_KEY

# Expected output:
# GH_CONFIG_APP_ID        123456
# GH_APP_INSTALLATION_ID  789012
# GH_CONFIG_PRIVATE_KEY   *******
```

#### B. Regenerate Private Key

1. Navigate to GitHub App settings:
   ```
   https://github.com/organizations/nathlan/settings/apps/<your-app>
   ```

2. Scroll to "Private keys" section

3. Click "Generate a private key"

4. Download the `.pem` file

5. Update repository secret:
   ```bash
   # Copy entire content including headers
   cat downloaded-key.pem | gh secret set GH_CONFIG_PRIVATE_KEY
   ```

6. **Verify format**: Private key must include:
   ```
   -----BEGIN RSA PRIVATE KEY-----
   [base64 encoded content]
   -----END RSA PRIVATE KEY-----
   ```

#### C. Verify App Installation

```bash
# Check app is installed in organization
gh api /orgs/nathlan/installations --jq '.installations[] | select(.app_slug == "your-app-name") | {id: .id, status: .suspended_at}'

# Should return installation ID and null for suspended_at
```

#### D. Check App Permissions

Verify the GitHub App has required permissions (see [TOKEN_PERMISSIONS.md](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md)):

- Repository administration: Read & Write
- Repository contents: Read & Write
- Metadata: Read

---

### Issue 2: "Error: GITHUB_APP_INSTALLATION_ID is not set"

**Symptoms**:
```
Error: GITHUB_APP_INSTALLATION_ID environment variable must be set
```

**Cause**: Missing `GH_APP_INSTALLATION_ID` repository variable

**Solution**:

```bash
# Find installation ID
# Method 1: Via API
gh api /orgs/nathlan/installations --jq '.installations[] | {app: .app_slug, id: .id}'

# Method 2: Via URL
# Navigate to: https://github.com/organizations/nathlan/settings/installations
# Click on your app
# URL will be: ...installations/XXXXXX (where XXXXXX is installation ID)

# Set variable
gh variable set GH_APP_INSTALLATION_ID --body "XXXXXX"
```

---

### Issue 3: "Error: could not find installations for app"

**Symptoms**:
```
Error: GET https://api.github.com/app/installations: 404 Not Found
```

**Causes**:
- GitHub App not installed in organization
- Wrong App ID
- App suspended or uninstalled

**Solutions**:

#### A. Install/Reinstall App

```bash
# Navigate to app installation page
open "https://github.com/organizations/nathlan/settings/installations"

# Click "Configure" next to your app (or "Install" if not present)
# Select repositories or "All repositories"
# Click "Install" or "Save"
```

#### B. Verify App ID

```bash
# Check app details
gh api /orgs/nathlan/installations

# Compare app_id in response with GH_CONFIG_APP_ID variable
gh variable get GH_CONFIG_APP_ID
```

---

## Workflow Failures

### Issue 4: Workflow doesn't trigger

**Symptoms**:
- Push to `main` or create PR, but workflow doesn't start
- Manual trigger not available

**Causes**:
- Workflow file not in `.github/workflows/`
- YAML syntax error
- Path filters excluding changes
- Workflow disabled

**Solutions**:

#### A. Verify Workflow File Location

```bash
# Check file exists
ls -la .github/workflows/github-terraform.yml

# Verify on main branch
git branch
git log --oneline -1 .github/workflows/github-terraform.yml
```

#### B. Validate YAML Syntax

```bash
# Use yamllint
yamllint .github/workflows/github-terraform.yml

# Or use online validator
# Copy workflow content to: https://www.yamllint.com/
```

#### C. Check Path Filters

Workflow triggers on changes to:
- `terraform-configs/new-repository/**`
- `.github/workflows/github-terraform.yml`

If changes are elsewhere, workflow won't trigger.

**Workaround**: Use manual trigger:
```bash
gh workflow run github-terraform.yml --ref main
```

#### D. Check Workflow Status

```bash
# List all workflows (check if disabled)
gh workflow list

# Enable if disabled
gh workflow enable github-terraform.yml
```

---

### Issue 5: "Unable to download artifact"

**Symptoms**:
```
Error: Unable to download artifact 'terraform-plan': Artifact not found
```

**Causes**:
- Plan job didn't complete
- Artifact expired (>30 days)
- Upload failed in plan job

**Solutions**:

#### A. Check Plan Job Status

```bash
# View workflow run
gh run view <run-id>

# Check if plan job succeeded
gh run view <run-id> --log | grep "Upload Plan Artifact"
```

#### B. Re-run Workflow

```bash
# Re-run failed jobs
gh run rerun <run-id> --failed

# Or re-run entire workflow
gh run rerun <run-id>
```

#### C. Check Artifact Storage

```bash
# List artifacts for run
gh api repos/nathlan/github-config/actions/runs/<run-id>/artifacts

# If empty, plan job failed to upload
```

---

### Issue 6: "Process completed with exit code 1"

**Symptoms**:
- Generic failure message
- No clear error in summary

**Solution**: View detailed logs

```bash
# Method 1: CLI
gh run view <run-id> --log-failed

# Method 2: Download full logs
gh run view <run-id> --log > workflow-logs.txt

# Method 3: Web UI
# Actions tab → Select run → Click failed job → Expand failed step
```

Common exit code 1 causes:
- Terraform validation failed
- Format check failed (`terraform fmt`)
- TFLint violations
- Checkov security violations (with `soft_fail: false`)

---

## Terraform Errors

### Issue 7: "Error: Reference to undeclared variable"

**Symptoms**:
```
Error: Reference to undeclared variable
│ on main.tf line 10, in resource "github_repository" "repo":
│ 10:   name = var.unknown_variable
```

**Cause**: Using variable not defined in `variables.tf`

**Solution**:

```bash
# Add variable definition
cat >> terraform-configs/new-repository/variables.tf <<EOF

variable "unknown_variable" {
  description = "Description of the variable"
  type        = string
  default     = "default-value"
}
EOF

# Or remove reference from main.tf
# Edit main.tf and remove/replace the variable reference
```

---

### Issue 8: "Error: Insufficient repository permissions"

**Symptoms**:
```
Error: POST https://api.github.com/repos/nathlan/repo-name/...: 403 Forbidden
```

**Cause**: GitHub App lacks required permissions

**Solution**:

#### A. Update GitHub App Permissions

1. Navigate to: `https://github.com/organizations/nathlan/settings/apps/<your-app>`

2. Click "Permissions" tab

3. Update permissions (see [TOKEN_PERMISSIONS.md](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md)):
   - Repository administration: **Read & Write**
   - Repository contents: **Read & Write**
   - Metadata: **Read**
   - Actions: **Read & Write**

4. Click "Save changes"

5. **Accept pending changes**:
   - Go to: `https://github.com/organizations/nathlan/settings/installations`
   - Click "Configure" next to your app
   - Review and accept permission changes

#### B. Verify Permissions Applied

```bash
# Check app permissions
gh api /orgs/nathlan/installations/<installation-id> --jq '.permissions'
```

---

### Issue 9: "Error: Repository already exists"

**Symptoms**:
```
Error: POST https://api.github.com/orgs/nathlan/repos: 422 Unprocessable Entity
name already exists on this account
```

**Cause**: Repository with same name already exists

**Solutions**:

#### A. Import Existing Repository

```bash
cd terraform-configs/new-repository

# Import existing repository into state
terraform import github_repository.repo existing-repo-name

# Terraform will now manage existing repository
```

#### B. Change Repository Name

```hcl
# Edit terraform-configs/new-repository/terraform.tfvars
repository_name = "new-unique-repo-name"
```

#### C. Delete Existing Repository (⚠️ Destructive)

```bash
# Via gh CLI
gh repo delete nathlan/existing-repo-name --confirm

# Or via web UI
# Navigate to repository → Settings → Danger Zone → Delete repository
```

---

### Issue 10: "Error: Invalid value for variable"

**Symptoms**:
```
Error: Invalid value for variable
│ on variables.tf line 15:
│ 15: variable "repository_visibility" {
│ 
│ The given value does not match the validation rule
```

**Cause**: Variable value doesn't meet validation constraints

**Solution**:

```bash
# Check validation rules in variables.tf
grep -A 5 "repository_visibility" terraform-configs/new-repository/variables.tf

# Example fix:
# If visibility is "internal" but org doesn't support it, use "private"
```

Common validation errors:
- `repository_visibility`: Must be `public`, `private`, or `internal`
- `repository_name`: Must match `^[a-zA-Z0-9._-]+$`
- `branch_protection_required_approving_review_count`: Must be 0-6

---

## Security Scan Issues

### Issue 11: Checkov fails with security violations

**Symptoms**:
```
Check: CKV_GIT_X: "Description of check"
FAILED for resource: github_repository.repo
```

**Causes**:
- Configuration doesn't meet security best practices
- `soft_fail: false` in workflow (by design)

**Solutions**:

#### A. Fix Security Issue (Recommended)

Review Checkov output and update configuration:

```hcl
# Example: Enable vulnerability alerts
resource "github_repository" "repo" {
  name = var.repository_name
  
  # Add missing security setting
  vulnerability_alerts = true
}
```

#### B. Skip Specific Check (with justification)

Edit `.checkov.yml`:

```yaml
skip-check:
  - CKV_GIT_1  # Justification: Repository visibility is configurable
```

**⚠️ Warning**: Only skip checks with valid security justification

#### C. View Detailed Security Findings

```bash
# Download SARIF results
gh api repos/nathlan/github-config/code-scanning/alerts \
  --jq '.[] | select(.tool.name == "checkov")'

# Or view in GitHub UI
# Security tab → Code scanning alerts → Filter by "checkov"
```

---

### Issue 12: TFLint fails

**Symptoms**:
```
Error: Unsupported attribute
  on main.tf line 50:
  50:   unsupported_attribute = "value"
```

**Causes**:
- Invalid Terraform syntax
- Deprecated resource attributes
- Missing required attributes
- Naming convention violations

**Solutions**:

#### A. Fix Linting Errors

```bash
# Run TFLint locally for detailed output
cd terraform-configs/new-repository

tflint --init
tflint --format compact

# Fix reported issues in Terraform files
```

#### B. Update TFLint Configuration

Edit `.tflint.hcl` to adjust rules:

```hcl
# Disable specific rule
rule "terraform_naming_convention" {
  enabled = false
}
```

#### C. Update to Latest Provider Version

```bash
# Update provider version in terraform.tf
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11.0"  # Update to latest
    }
  }
}

# Update lock file
terraform init -upgrade
```

---

## Drift Detection Issues

### Issue 13: False positive drift detection

**Symptoms**:
- Drift detected daily, but no actual changes made
- Plan shows changes to computed attributes

**Causes**:
- Terraform state out of sync
- Computed attributes changing (timestamps, etc.)
- API inconsistencies

**Solutions**:

#### A. Identify Drifting Attributes

```bash
# View detailed plan output
gh run view <run-id> --log | grep "will be updated"

# Check if changes are cosmetic
# Example: "updated_at" field changing
```

#### B. Refresh State

```bash
cd terraform-configs/new-repository

# Refresh Terraform state
export GITHUB_APP_ID="your-app-id"
export GITHUB_APP_INSTALLATION_ID="your-installation-id"
export GITHUB_APP_PEM_FILE="$(cat path-to-key.pem)"

terraform init
terraform refresh -var="github_organization=nathlan"
```

#### C. Ignore Cosmetic Changes

Add lifecycle block to resource:

```hcl
resource "github_repository" "repo" {
  name = var.repository_name
  
  lifecycle {
    ignore_changes = [
      # Ignore timestamp changes
      updated_at,
    ]
  }
}
```

---

### Issue 14: Legitimate drift not detected

**Symptoms**:
- Manual changes made, but drift detection doesn't report them

**Causes**:
- Drift detection workflow not running
- Changes to attributes not tracked by Terraform
- Schedule not configured

**Solutions**:

#### A. Verify Schedule Configuration

```bash
# Check workflow file
grep -A 2 "schedule:" .github/workflows/github-terraform.yml

# Should show:
# schedule:
#   - cron: '0 8 * * *'
```

#### B. Manually Trigger Drift Detection

```bash
# Trigger workflow manually
gh workflow run github-terraform.yml --ref main -f terraform_action=plan
```

#### C. Check Recent Workflow Runs

```bash
# View scheduled runs
gh run list --workflow=github-terraform.yml --event=schedule --limit 5

# If no runs, schedule may be disabled
```

---

## Environment & Approval Issues

### Issue 15: Deployment blocked waiting for approval

**Symptoms**:
- Apply job shows "Waiting for approval"
- No reviewers configured

**Solution**:

#### A. Configure Environment Reviewers

```bash
# Via web UI (recommended):
# 1. Settings → Environments → github-admin
# 2. Click "Required reviewers"
# 3. Add users/teams
# 4. Save protection rules

# Verify configuration
gh api repos/nathlan/github-config/environments/github-admin --jq '.protection_rules'
```

#### B. Approve Pending Deployment

```bash
# Via web UI:
# Actions tab → Select workflow run → "Review deployments" → Approve

# Or use API:
gh api --method POST \
  repos/nathlan/github-config/actions/runs/<run-id>/pending_deployments \
  -f environment_ids[]='<environment-id>' \
  -f state='approved' \
  -f comment='Approved for deployment'
```

---

### Issue 16: "Environment not found"

**Symptoms**:
```
Error: The environment 'github-admin' does not exist
```

**Cause**: Environment not created in repository settings

**Solution**:

```bash
# Create environment via API
gh api --method PUT \
  repos/nathlan/github-config/environments/github-admin

# Or via web UI:
# Settings → Environments → New environment
# Name: github-admin
# Add protection rules (required reviewers)
# Save
```

---

## Resource-Specific Issues

### Issue 17: Branch protection ruleset conflicts

**Symptoms**:
```
Error: Error creating repository ruleset: 422 Unprocessable Entity
ruleset name already exists
```

**Cause**: Ruleset with same name already exists

**Solutions**:

#### A. Import Existing Ruleset

```bash
# List existing rulesets
gh api repos/nathlan/<repo-name>/rulesets --jq '.[] | {id, name}'

# Import into Terraform state
terraform import github_repository_ruleset.main_branch_protection <ruleset-id>
```

#### B. Use Different Ruleset Name

```hcl
resource "github_repository_ruleset" "main_branch_protection" {
  name       = "Protect main branch - Terraform"  # Add suffix
  repository = github_repository.repo.name
  # ...
}
```

#### C. Delete Conflicting Ruleset

```bash
# Via gh CLI
gh api --method DELETE repos/nathlan/<repo-name>/rulesets/<ruleset-id>

# Or via web UI
# Repository → Settings → Rules → Delete ruleset
```

---

### Issue 18: GitHub Actions permissions not applying

**Symptoms**:
- Actions can't create PRs
- Actions can't approve PRs
- Permission denied errors in Actions workflows

**Solutions**:

#### A. Verify Workflow Permissions

```hcl
# Check configuration in main.tf
resource "github_workflow_repository_permissions" "repo" {
  repository = github_repository.repo.name
  
  can_approve_pull_request_reviews = true  # Must be true
}
```

#### B. Check Repository Actions Settings

```bash
# Via gh CLI
gh api repos/nathlan/<repo-name>/actions/permissions --jq '.allowed_actions'

# Should return: "all"
```

#### C. Update Workflow File Permissions

Ensure workflow has required permissions:

```yaml
permissions:
  contents: write
  pull-requests: write
  issues: write
```

---

## Debug Mode

### Enable Terraform Debug Logging

Add to workflow environment variables:

```yaml
env:
  TF_LOG: DEBUG  # or TRACE for verbose output
  TF_LOG_PATH: terraform-debug.log
```

### Enable GitHub Actions Debug Logging

```bash
# Set repository secrets
gh secret set ACTIONS_RUNNER_DEBUG --body "true"
gh secret set ACTIONS_STEP_DEBUG --body "true"

# Re-run workflow to see detailed logs
```

### Download Full Workflow Logs

```bash
# Download logs archive
gh run download <run-id>

# Extract and view
unzip *.zip
cat */*/terraform-plan.txt
```

### Local Testing

Test Terraform locally before pushing:

```bash
cd terraform-configs/new-repository

# Set credentials
export GITHUB_APP_ID="123456"
export GITHUB_APP_INSTALLATION_ID="789012"
export GITHUB_APP_PEM_FILE="$(cat ~/path/to/private-key.pem)"

# Initialize
terraform init

# Validate
terraform validate

# Format
terraform fmt -recursive

# Plan
terraform plan -var="github_organization=nathlan"

# Apply (use with caution)
terraform apply -var="github_organization=nathlan"
```

---

## Getting Help

### Self-Service Resources

- **Terraform GitHub Provider Docs**: https://registry.terraform.io/providers/integrations/github/latest/docs
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Checkov Docs**: https://www.checkov.io/
- **TFLint Docs**: https://github.com/terraform-linters/tflint

### Repository Documentation

- [Deployment Guide](./DEPLOYMENT.md)
- [Rollback Procedures](./ROLLBACK.md)
- [Token Permissions](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md)

### Reporting Issues

When reporting issues, include:

1. **Workflow run URL**: `https://github.com/nathlan/github-config/actions/runs/<run-id>`
2. **Error message**: Copy exact error from logs
3. **Terraform version**: Check workflow or run `terraform version`
4. **Provider version**: Check `terraform.tf` or `.terraform.lock.hcl`
5. **Recent changes**: What was changed before issue occurred
6. **Steps to reproduce**: How to trigger the issue

### Emergency Contacts

- **GitHub Support**: https://support.github.com
- **Terraform Support**: https://support.hashicorp.com
- **Team Lead**: [Contact information]
- **On-Call**: [Contact method]

---

## Common Error Reference

| Error Message | Issue # | Quick Fix |
|--------------|---------|-----------|
| `Invalid GitHub App credentials` | [#1](#issue-1-error-invalid-github-app-credentials) | Regenerate private key |
| `GITHUB_APP_INSTALLATION_ID is not set` | [#2](#issue-2-error-github_app_installation_id-is-not-set) | Set repository variable |
| `could not find installations` | [#3](#issue-3-error-could-not-find-installations-for-app) | Install/reinstall app |
| `Artifact not found` | [#5](#issue-5-unable-to-download-artifact) | Re-run workflow |
| `Insufficient repository permissions` | [#8](#issue-8-error-insufficient-repository-permissions) | Update app permissions |
| `Repository already exists` | [#9](#issue-9-error-repository-already-exists) | Import or rename |
| `Checkov security violations` | [#11](#issue-11-checkov-fails-with-security-violations) | Fix issues or skip checks |
| `TFLint failures` | [#12](#issue-12-tflint-fails) | Fix linting errors |
| `Environment not found` | [#16](#issue-16-environment-not-found) | Create environment |
| `Ruleset name already exists` | [#17](#issue-17-branch-protection-ruleset-conflicts) | Import or rename |

---

**Pro Tip**: Most issues can be resolved by:
1. Verifying credentials (App ID, Installation ID, Private Key)
2. Checking Terraform configuration locally (`terraform validate`)
3. Reviewing detailed workflow logs (`gh run view --log-failed`)
4. Ensuring GitHub App has correct permissions

If issue persists after troubleshooting, see [Rollback Procedures](./ROLLBACK.md) to revert to last known good state.
