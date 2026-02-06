# GitHub App Authentication for Terraform

This document outlines how to authenticate the Terraform GitHub provider using a GitHub App, which is the recommended and only supported method for this configuration.

## Why GitHub App?

GitHub Apps provide:
- ✅ More granular permissions than Personal Access Tokens
- ✅ Better audit trail with actions attributed to the app
- ✅ Automatic token rotation and improved security
- ✅ Can be installed per organization/repository
- ✅ Tokens expire after 1 hour (automatic refresh by Terraform)
- ✅ Better suited for CI/CD and automation

## Creating a GitHub App

### Step 1: Create the GitHub App

1. Go to your **Organization Settings** → **Developer settings** → **GitHub Apps**
2. Click **New GitHub App**
3. Fill in the required fields:
   - **GitHub App name**: `terraform-automation` (or your choice)
   - **Homepage URL**: Your organization URL
   - **Webhook**: Uncheck "Active" (not needed for Terraform)

### Step 2: Set Permissions

Configure these **Repository permissions**:

| Permission | Access Level | Required For |
|------------|-------------|--------------|
| **Actions** | Read and write | Managing Actions permissions, variables |
| **Administration** | Read and write | Creating repositories, branch protection, settings |
| **Contents** | Read and write | Repository initialization, managing content |
| **Metadata** | Read | Automatically included - repository information |
| **Workflows** | Read and write | Managing workflow permissions |

Configure these **Organization permissions** (if managing org-owned repositories):

| Permission | Access Level | Required For |
|------------|-------------|--------------|
| **Administration** | Read | Reading organization data |

### Step 3: Generate Private Key

1. After creating the app, scroll down to **Private keys**
2. Click **Generate a private key**
3. Save the downloaded `.pem` file securely
4. **Important**: Keep this file secure - it's your authentication credential

### Step 4: Install the App

1. In your GitHub App settings, click **Install App**
2. Select your organization
3. Choose:
   - **All repositories** (if you want Terraform to manage any repo), OR
   - **Only select repositories** (choose specific repos)
4. Click **Install**
5. Note the **Installation ID** from the URL (e.g., `https://github.com/organizations/YOUR_ORG/settings/installations/12345678` → ID is `12345678`)

### Step 5: Get Your App ID

1. Go back to your GitHub App settings
2. Find **App ID** near the top of the page
3. Note this number (e.g., `123456`)

## Configuring Terraform with GitHub App

### Environment Variables (Recommended)

The Terraform provider looks for these environment variables:

```bash
export GITHUB_APP_ID="123456"                           # Your App ID
export GITHUB_APP_INSTALLATION_ID="78910"               # Your Installation ID
export GITHUB_APP_PEM_FILE="/path/to/private-key.pem"  # Path to PEM file
```

**For CI/CD** (when you can't use file paths):

```bash
export GH_CONFIG_APP_ID="123456"              # Your App ID
export GH_APP_INSTALLATION_ID="78910"  # Your Installation ID
export GH_CONFIG_PRIVATE_KEY="$(cat /path/to/private-key.pem)"  # PEM content as string
```

### CI/CD Configuration

#### GitHub Actions

Store these as **Repository Secrets** or **Organization Secrets**:

- **`GH_CONFIG_APP_ID`** (Variable) - Your GitHub App ID
- **`GH_APP_INSTALLATION_ID`** (Variable) - Your Installation ID  
- **`GH_CONFIG_PRIVATE_KEY`** (Secret) - Full content of your PEM file

Example workflow:

```yaml
name: Terraform Apply
on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        
      - name: Terraform Init
        env:
          GITHUB_APP_ID: ${{ vars.GH_CONFIG_APP_ID }}
          GITHUB_APP_INSTALLATION_ID: ${{ vars.GH_APP_INSTALLATION_ID }}
          GITHUB_APP_PEM_FILE: ${{ secrets.GH_CONFIG_PRIVATE_KEY }}
        run: terraform init
        
      - name: Terraform Apply
        env:
          GITHUB_APP_ID: ${{ vars.GH_CONFIG_APP_ID }}
          GITHUB_APP_INSTALLATION_ID: ${{ vars.GH_APP_INSTALLATION_ID }}
          GITHUB_APP_PEM_FILE: ${{ secrets.GH_CONFIG_PRIVATE_KEY }}
        run: terraform apply -auto-approve -var="github_organization=your-org"
```

## Variable Names Reference

### For CI/CD (what the workflow agent expects):

| Variable Name | Type | Description |
|---------------|------|-------------|
| `GH_CONFIG_APP_ID` | Variable | GitHub App ID (numeric) - **This is what you should set** |
| `GH_APP_INSTALLATION_ID` | Variable | Installation ID (numeric) - **This is what you should set** |
| `GH_CONFIG_PRIVATE_KEY` | Secret | Full PEM file content - **This is the secret name to use** |

### How Terraform reads them:

The Terraform provider configuration maps these to:
- `GH_CONFIG_APP_ID` or `GITHUB_APP_ID` → `var.app_id`
- `GH_APP_INSTALLATION_ID` or `GITHUB_APP_INSTALLATION_ID` → `var.app_installation_id`
- `GH_CONFIG_PRIVATE_KEY` or `GITHUB_APP_PEM_FILE` → `var.app_pem_file`

## Terraform Provider Configuration

The provider is configured in `provider.tf` to use GitHub App authentication:

```hcl
provider "github" {
  owner = var.github_organization
  
  app_auth {
    id              = var.app_id              # from GITHUB_APP_ID or GH_CONFIG_APP_ID
    installation_id = var.app_installation_id # from GITHUB_APP_INSTALLATION_ID or GH_APP_INSTALLATION_ID
    pem_file        = var.app_pem_file        # from GITHUB_APP_PEM_FILE (path) or GH_CONFIG_PRIVATE_KEY (content)
  }
}
```

## Security Best Practices

### ✅ DO:
- Store the PEM file securely with restricted permissions (`chmod 600`)
- Use separate apps for different environments (dev, staging, prod)
- Use GitHub's secret scanning to detect leaked keys
- Rotate private keys periodically
- Use minimum required permissions for each app
- Store credentials in secure secret management systems
- Use organization-level apps when managing multiple repositories

### ❌ DON'T:
- Commit PEM files to Git repositories
- Share PEM files via email or chat
- Use the same app across different organizations
- Grant broader permissions than needed
- Store PEM files in world-readable locations
- Hard-code credentials in Terraform files

## GitHub MCP Server PR Creation (Separate from Terraform)

If you want to use the **GitHub MCP (Model Context Protocol) server** to create pull requests, you need a separate Fine-Grained Personal Access Token.

### MCP Server Fine-Grained PAT Permissions

**Repository permissions**:
- ✅ `Contents` - **Read and write** (create branches, commit files)
- ✅ `Pull requests` - **Read and write** (create, update PRs)
- ✅ `Metadata` - **Read** (automatically included)

### MCP Server Configuration

Configure your MCP server (e.g., in `.windsurf/mcp.json`):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "github_pat_YOUR_TOKEN_HERE"
      }
    }
  }
}
```

### Important: Keep Terraform and MCP Separate

- **Terraform + GitHub App**: Manages infrastructure through CI/CD
- **MCP Server + Fine-Grained PAT**: Creates pull requests interactively
- **Do NOT bypass Terraform** - all infrastructure changes go through Terraform

## References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [Terraform GitHub Provider - GitHub App Auth](https://registry.terraform.io/providers/integrations/github/latest/docs#github-app-installation)
- [GitHub App Permissions Reference](https://docs.github.com/en/rest/authentication/permissions-required-for-github-apps)
