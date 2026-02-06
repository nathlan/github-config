# GitHub Token Permissions Required

This document outlines the exact permissions needed for the GitHub token (Personal Access Token or GitHub App) to successfully apply this Terraform configuration.

## Overview

To create and manage a GitHub repository with branch protection, Actions configuration, and Copilot settings, your authentication token needs specific permissions across repository and organization scopes.

## Authentication Options

### Option 1: Personal Access Token (Classic) - Recommended for Individual Use

Create a **Classic** Personal Access Token with these scopes:

- ✅ `repo` - Full control of private repositories
  - Includes: repo:status, repo_deployment, public_repo, repo:invite, security_events
  - **Required for**: Creating repositories, managing settings, branch protection
  
- ✅ `admin:org` - Full control of organizations and teams
  - Includes: write:org, read:org
  - **Required for**: Reading organization data, managing organization-owned repositories
  
- ✅ `workflow` - Update GitHub Action workflows
  - **Required for**: Configuring Actions permissions, workflow permissions, repository variables

**How to create:**
1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select the scopes above
4. Generate and copy the token
5. Set it as an environment variable: `export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"`

### Option 2: Fine-Grained Personal Access Token - More Secure, Recommended for Production

Create a **Fine-Grained** Personal Access Token with these permissions:

**Repository permissions** (for the target repository or all repositories):
- ✅ `Actions` - Read and write
  - **Required for**: Managing Actions permissions, variables
  
- ✅ `Administration` - Read and write
  - **Required for**: Creating repositories, managing repository settings, branch protection rulesets
  
- ✅ `Contents` - Read and write
  - **Required for**: Repository initialization, content management
  
- ✅ `Metadata` - Read (automatically included)
  - **Required for**: Basic repository information
  
- ✅ `Workflows` - Read and write
  - **Required for**: Managing workflow permissions

**Organization permissions** (if managing organization-owned repositories):
- ✅ `Administration` - Read
  - **Required for**: Reading organization data

**How to create:**
1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Set repository access (all repositories or select repositories)
4. Configure the permissions above
5. Generate and copy the token
6. Set it as an environment variable: `export GITHUB_TOKEN="github_pat_xxxxxxxxxxxx"`

### Option 3: GitHub App - Best for Automation and CI/CD

Create a GitHub App with these permissions:

**Repository permissions:**
- ✅ `Actions` - Read and write
- ✅ `Administration` - Read and write
- ✅ `Contents` - Read and write
- ✅ `Workflows` - Read and write

**Organization permissions:**
- ✅ `Administration` - Read (if managing org-owned repos)

**Advantages:**
- More granular permissions
- Better audit trail
- Automatic token rotation
- Can be installed per organization/repository

**How to use with Terraform:**
1. Create a GitHub App in your organization settings
2. Generate a private key for the app
3. Install the app in your organization
4. Use the app ID and private key for authentication (requires additional Terraform provider configuration)

## Setting Up the Token

### For Local Development

```bash
# Export the token as an environment variable (recommended)
export GITHUB_TOKEN="your-token-here"

# Verify it's set
echo $GITHUB_TOKEN

# Run Terraform
terraform plan -var="github_organization=your-org"
```

### For CI/CD Pipelines

**GitHub Actions:**
```yaml
- name: Terraform Apply
  env:
    GITHUB_TOKEN: ${{ secrets.GH_PAT }}
  run: |
    terraform apply -auto-approve
```

**GitLab CI:**
```yaml
terraform:
  variables:
    GITHUB_TOKEN: $CI_GITHUB_TOKEN
  script:
    - terraform apply -auto-approve
```

**Jenkins:**
```groovy
withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
    sh 'terraform apply -auto-approve'
}
```

## Security Best Practices

### ✅ DO:
- Use fine-grained tokens when possible
- Set token expiration dates
- Store tokens in secure secret management systems (Vault, AWS Secrets Manager, etc.)
- Use environment variables, never commit tokens to version control
- Rotate tokens regularly
- Use GitHub Apps for automated systems
- Limit token scope to only required permissions
- Use repository-scoped tokens when managing specific repositories

### ❌ DON'T:
- Commit tokens to Git repositories
- Share tokens via email or chat
- Use tokens with broader permissions than needed
- Store tokens in plain text files
- Use the same token across multiple systems
- Leave tokens without expiration dates

## Verifying Token Permissions

Before running Terraform, verify your token has the correct permissions:

```bash
# Test authentication
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

# Check scopes (for classic tokens)
curl -I -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep x-oauth-scopes

# Test organization access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/orgs/your-org

# Test repository creation permission (dry-run)
curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/orgs/your-org/repos \
  -d '{"name":"test-repo-permissions-check","private":true}' \
  --fail || echo "Permission check failed"
```

## Terraform Provider Configuration

The provider is configured in `provider.tf` to use the `GITHUB_TOKEN` environment variable automatically:

```hcl
provider "github" {
  owner = var.github_organization
  # Token is read from GITHUB_TOKEN environment variable
}
```

Alternative explicit configuration (not recommended - less secure):

```hcl
provider "github" {
  owner = var.github_organization
  token = var.github_token  # Use this only if you manage token via Terraform variables
}
```

## Troubleshooting

### Error: 401 Unauthorized
- **Cause**: Token is missing, invalid, or expired
- **Solution**: Verify `GITHUB_TOKEN` is set and valid: `echo $GITHUB_TOKEN`

### Error: 403 Forbidden
- **Cause**: Token lacks required permissions
- **Solution**: Verify token has all required scopes listed above

### Error: Resource already exists
- **Cause**: Repository name already exists in organization
- **Solution**: Choose a different repository name or import the existing repository

### Error: 404 Not Found (for organization)
- **Cause**: Token doesn't have access to the organization or org doesn't exist
- **Solution**: Verify organization name and token has `admin:org` or `read:org` permission

## Minimum Permissions Summary

**To create a repository with all features in this configuration:**

| Resource | Permission Required |
|----------|-------------------|
| Repository creation | `repo` or `Administration: Write` |
| Branch protection rulesets | `repo` or `Administration: Write` |
| Actions permissions | `workflow` or `Actions: Write` |
| Actions variables | `workflow` or `Actions: Write` |
| Workflow permissions | `workflow` or `Workflows: Write` |
| Organization data (read) | `admin:org` or `Organization Admin: Read` |

## References

- [GitHub PAT Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Fine-Grained PAT Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token)
- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [Terraform GitHub Provider Authentication](https://registry.terraform.io/providers/integrations/github/latest/docs#authentication)
