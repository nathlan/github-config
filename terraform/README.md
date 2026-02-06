# GitHub Repository Terraform Configuration

This Terraform configuration creates and manages multiple GitHub repositories with the following features:

## Resources Managed

### Repository Configuration
- **Repositories**: Creates multiple repositories in your GitHub organization with configurable settings
- **Auto-initialization**: Repositories are created with an initial README
- **Merge Settings**: Configures merge commit, squash merge, and rebase merge options
- **Security**: Enables vulnerability alerts for dependencies

### Branch Protection
- **Main Branch Protection**: Implements a repository ruleset for the `main` branch with:
  - Required pull request reviews (configurable count per repository)
  - Protection against deletion
  - Protection against force pushes
  - Stale review dismissal on new commits
  - Bypass permission for repository admins on pull requests
  - **Note**: Rulesets require GitHub Pro or public repositories. For private repos on free tier, use `github_branch_protection` instead.

### GitHub Actions & Copilot Configuration
- **Actions Permissions**: Enables GitHub Actions with permissions to run all actions
- **Workflow Permissions**: Configures GITHUB_TOKEN default permissions to "read" (more secure) and allows GitHub Actions (including Copilot) to create and work with pull requests
- **Copilot Agent Firewall**: Configures the Copilot agent firewall allowlist via repository variable to permit outbound connections to:
  - `registry.terraform.io` - Terraform Registry for provider/module downloads
  - `checkpoint-api.hashicorp.com` - HashiCorp's update/telemetry service
  - `api0.prismacloud.io` - Prisma Cloud API for security scanning
  - **Note**: This configuration is consistent across all repositories
  - **Note**: Requires GitHub App with "Actions: Read and write" permission. Set `manage_copilot_firewall_variable = false` if you encounter permission errors.

## Prerequisites

### GitHub Token
You need a GitHub Personal Access Token (PAT) or GitHub App with the following permissions:

#### For Personal Access Token (Classic):
- `repo` - Full control of private repositories
- `admin:org` - Full control of organizations and teams (for organization-level settings)
- `workflow` - Update GitHub Action workflows

#### For Fine-Grained Personal Access Token:
**Repository permissions:**
- Administration: Read and write
- Actions: Read and write
- Contents: Read and write
- Metadata: Read (automatically included)
- Workflows: Read and write

**Organization permissions (if managing organization-owned repositories):**
- Administration: Read

#### For GitHub App:
**Repository permissions:**
- Actions: Read and write
- Administration: Read and write
- Contents: Read and write
- Workflows: Read and write

Set the token as an environment variable:
```bash
export GITHUB_TOKEN="your-token-here"
```

### Terraform
- Terraform >= 1.9.0
- GitHub Provider ~> 6.11

## Usage

### 1. Initialize Terraform
```bash
cd /tmp/gh-config-<timestamp>
terraform init
```

### 2. Review and Customize Variables
Edit the `terraform.tfvars` file with your values:

```hcl
github_organization = "your-org-name"

repositories = [
  {
    name                                          = "my-first-repo"
    description                                   = "My first repository"
    visibility                                    = "private"
    branch_protection_required_approving_review_count = 1
  },
  {
    name                                          = "my-second-repo"
    description                                   = "My second repository"
    visibility                                    = "private"
    branch_protection_required_approving_review_count = 2
  }
]

# Optional: Customize Copilot firewall allowlist (applies to all repositories)
copilot_firewall_allowlist = [
  "registry.terraform.io",
  "checkpoint-api.hashicorp.com",
  "api0.prismacloud.io",
  "custom-domain.example.com"
]
```

Or provide variables via command line:
```bash
terraform plan -var="github_organization=your-org"
```

### 3. Plan
Review the changes Terraform will make:
```bash
terraform plan -var="github_organization=your-org"
```

### 4. Apply
Apply the configuration to create the repository:
```bash
terraform apply -var="github_organization=your-org"
```

### 5. Verify
After successful apply, Terraform will output:
- Repository details for each created repository (ID, name, URLs)
- Copilot firewall allowlist configuration
- Branch protection ruleset IDs
- Total count of repositories created

## Configuration Options

### Variables

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `github_organization` | GitHub organization name | string | - | Yes |
| `repositories` | List of repository objects to create | list(object) | - | Yes |
| `repositories[].name` | Repository name | string | - | Yes |
| `repositories[].description` | Repository description | string | - | Yes |
| `repositories[].visibility` | Repository visibility (public/private/internal) | string | - | Yes |
| `repositories[].branch_protection_required_approving_review_count` | Required PR approvals | number | - | Yes |
| `copilot_firewall_allowlist` | Additional domains for Copilot agent (consistent across all repos) | list(string) | See defaults | No |
| `enable_copilot_pr_from_actions` | Allow Copilot to create PRs (applies to all repos) | bool | `true` | No |
| `manage_copilot_firewall_variable` | Create Copilot firewall variable (requires GitHub App with Actions: Read and write permission) | bool | `true` | No |

### Outputs

| Output | Description |
|--------|-------------|
| `repositories` | Map of created repositories with details (ID, name, URLs, branch protection ID) |
| `copilot_firewall_allowlist` | Configured allowlist domains |
| `organization` | Organization name |
| `repository_count` | Number of repositories created |

## Security Considerations

### 🟢 Low Risk Operations
- Creating new repositories
- Configuring repository settings
- Adding branch protection rules
- Setting up Actions variables

### ⚠️ Important Notes
1. **Token Security**: Never commit your GitHub token to version control. Always use environment variables or secure secret management.
2. **Permissions**: Ensure the token has minimum required permissions for your use case.
3. **Branch Protection**: The ruleset allows repository admins to bypass protection on pull requests, which is necessary for automated workflows.
4. **Copilot Firewall**: The allowlist extends (not replaces) the default allowed domains and is consistent across all repositories. Review the [Copilot allowlist reference](https://docs.github.com/en/copilot/reference/copilot-allowlist-reference) for defaults.
5. **Multiple Repositories**: Each repository can have different branch protection settings, but Copilot firewall rules are shared across all repositories.

### State Management
This configuration uses local state by default. For production use or team collaboration, consider using remote state:
- **Terraform Cloud**: Managed state with collaboration features
- **S3 + DynamoDB**: AWS-based state backend with locking
- **Azure Blob Storage**: Azure-based state backend
- **GCS**: Google Cloud Storage state backend

To configure remote state, add a `backend` block to `terraform.tf`.

## Copilot Agent Firewall Details

The Copilot agent firewall restricts outbound internet access from the Copilot coding agent to prevent data exfiltration. By default, GitHub provides a comprehensive allowlist including:
- Operating system package repositories (apt, yum, apk, etc.)
- Container registries (Docker Hub, ECR, ACR, GCR, etc.)
- Language package managers (npm, PyPI, Maven, RubyGems, etc.)
- Common development tools and APIs

This configuration adds **custom domains** via the `COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS` repository variable, which extends the default allowlist for:
- **Terraform Registry**: Required for Copilot to fetch Terraform providers and modules
- **HashiCorp Checkpoint API**: For version checking and telemetry
- **Prisma Cloud API**: For security scanning and compliance checks

### How It Works
1. The repository variable is set with comma-separated domain names
2. GitHub Copilot agent reads this variable when running in GitHub Actions
3. The firewall permits outbound connections only to default + custom allowlist domains
4. Blocked requests result in warnings/comments on PRs with details about the denied connection

### Testing the Configuration
After applying this Terraform configuration, you can verify the Copilot firewall is working by:
1. Triggering a Copilot-generated PR from an Action
2. Checking that Copilot can access Terraform Registry and other allowlisted domains
3. Observing that connections to non-allowlisted domains are blocked and logged

## Next Steps

After creating this repository with Terraform:

1. **Clone the Repository**: Use the output clone URLs to clone the newly created repository
2. **Set Up Workflows**: Create GitHub Actions workflows to utilize Copilot for automated PR creation
3. **Configure Branch Protection Further**: Adjust branch protection settings as needed for your workflow
4. **Add Collaborators/Teams**: Use additional Terraform resources to grant access to teams or individuals
5. **Import Existing Resources**: If this configuration needs to match an existing repository, use `terraform import`

## Troubleshooting

### Common Issues

**"Resource already exists"**
- The repository name is already taken in your organization
- Solution: Choose a different `repository_name` or import the existing repository

**"401 Unauthorized"**
- GitHub token is missing or invalid
- Solution: Verify `GITHUB_TOKEN` environment variable is set correctly

**"403 Forbidden"**
- Token lacks required permissions
- Solution: Ensure token has `repo`, `admin:org`, and `workflow` scopes

**"Validation errors"**
- Invalid variable values
- Solution: Check variable validations and ensure values meet requirements

**Copilot can't access allowlisted domains**
- Variable not properly set
- Solution: Check that `COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS` variable exists in repository

## References

- [GitHub Terraform Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Copilot Agent Firewall Documentation](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/customize-the-agent-firewall)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication)
- [Copilot Allowlist Reference](https://docs.github.com/en/copilot/reference/copilot-allowlist-reference)

## License

This Terraform configuration is provided as-is for use in managing GitHub infrastructure.
