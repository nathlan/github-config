# GitHub Configuration - ALZ Workload Template Repository

This Terraform module manages the configuration of the `alz-workload-template` repository in the `nathlan` organization.

## Overview

This module manages:
- Repository settings (name, description, visibility, template flag)
- Repository features (issues, projects, wiki, discussions)
- Merge settings (squash, merge commit, rebase, auto-delete branches)
- Branch protection rules for the `main` branch
- Team access permissions
- Required status checks and pull request reviews

## Resources Managed

### Repository Configuration
- **github_repository.alz_workload_template**: Main repository settings including template flag, topics, and merge settings

### Branch Protection
- **github_repository_ruleset.main_branch_protection**: Modern ruleset-based branch protection for main branch
  - Requires 1 approving review
  - Requires status checks: validate, security, plan
  - Dismisses stale reviews on new pushes
  - Strict status checks (requires branches to be up-to-date)
- **github_branch_protection_v3.main_push_restrictions**: Legacy branch protection for push restrictions to platform-engineering team

### Team Access
- **github_team_repository.maintainers**: Grants maintain access to configured teams

## Prerequisites

1. **GitHub Token**: A GitHub Personal Access Token (PAT) or GitHub App token with the following scopes:
   - `repo` (full control of private repositories)
   - `admin:org` (for organization management)
   - `admin:repo_hook` (for managing webhooks)

2. **Required Teams**: The following teams must exist in the organization:
   - `platform-engineering` (for maintainer access and push restrictions)

3. **Terraform Version**: >= 1.9.0
4. **GitHub Provider**: ~> 6.0

## Usage

### Basic Usage

```hcl
# Set environment variable for authentication
export GITHUB_TOKEN="your_github_token_here"

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="github_organization=nathlan"

# Apply the configuration
terraform apply -var="github_organization=nathlan"
```

### Custom Configuration

```hcl
# terraform.tfvars (create this file locally, it's gitignored)
github_organization     = "nathlan"
repository_name         = "alz-workload-template"
repository_visibility   = "internal"
required_status_checks  = ["validate", "security", "plan", "custom-check"]
team_maintainers        = ["platform-engineering", "devops"]
```

### Importing Existing Resources

If the repository already exists, you'll need to import it:

```bash
# Import the repository
terraform import github_repository.alz_workload_template alz-workload-template

# Import team access (get team ID first)
export TEAM_ID=$(gh api orgs/nathlan/teams/platform-engineering --jq '.id')
terraform import 'github_team_repository.maintainers["platform-engineering"]' ${TEAM_ID}:alz-workload-template
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| github_organization | GitHub organization name | string | "nathlan" | no |
| repository_name | Name of the repository | string | "alz-workload-template" | no |
| repository_description | Description of the repository | string | "Template repository..." | no |
| repository_visibility | Repository visibility | string | "internal" | no |
| repository_topics | Topics for the repository | list(string) | ["azure", "terraform", ...] | no |
| required_status_checks | Required status checks | list(string) | ["validate", "security", "plan"] | no |
| team_maintainers | Teams with maintain access | list(string) | ["platform-engineering"] | no |
| push_allowance_teams | Teams allowed to push | list(string) | ["platform-engineering"] | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_id | The ID of the repository |
| repository_full_name | Full name (org/repo) |
| repository_html_url | HTML URL of the repository |
| repository_ssh_clone_url | SSH clone URL |
| repository_http_clone_url | HTTP clone URL |
| is_template | Whether repository is a template |
| branch_protection_ruleset_id | ID of the branch protection ruleset |
| team_access | Teams with access and their permissions |

## Security Considerations

### Authentication
- **Never** commit the `GITHUB_TOKEN` to version control
- Use environment variables or secure secret management systems
- Consider using GitHub Apps for more fine-grained permissions and better audit trails

### Branch Protection
- The configuration requires PR reviews before merging
- Status checks must pass before merging
- Conversation resolution is required
- Administrators can bypass in emergencies but it's logged

### Least Privilege
- Teams are granted only the minimum required permissions
- The `platform-engineering` team has maintain access (not admin)
- Push restrictions limit who can directly push to main

### Lifecycle Protection
- The repository resource has `prevent_destroy = true` to prevent accidental deletion

## Risk Assessment

**Risk Level**: 🟡 **MEDIUM**

### Potential Impacts
- **Branch Protection Changes**: May affect team workflow if rules are too restrictive
- **Merge Settings**: Changing merge methods affects commit history
- **Team Access**: Modifying access could lock out team members
- **Template Flag**: Disabling `is_template` would remove the "Use this template" functionality

### Recommended Review Process
1. Review all configuration changes in the PR
2. Ensure team members are aware of new branch protection rules
3. Verify required status checks exist in CI/CD workflows
4. Test the template functionality after applying changes
5. Monitor the first few PRs after applying to ensure workflows function correctly

## State Management

This configuration uses local state by default. For production use, consider:

1. **Terraform Cloud**: Managed state with UI and team collaboration
2. **S3 Backend**: With DynamoDB for locking
3. **Azure Blob Storage**: For Azure-native environments
4. **Remote Backend**: Any supported Terraform backend

Example remote backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket"
    key            = "github-config/alz-workload-template.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

## Maintenance

### Adding New Status Checks
Update the `required_status_checks` variable in your tfvars file:

```hcl
required_status_checks = ["validate", "security", "plan", "new-check"]
```

### Modifying Team Access
Update the `team_maintainers` variable to add or remove teams:

```hcl
team_maintainers = ["platform-engineering", "new-team"]
```

### Updating Branch Protection
Modify the `github_repository_ruleset` resource in `main.tf` to adjust protection rules.

## Known Limitations

### Conversation Resolution Requirement
The GitHub provider does not currently support setting "Require conversation resolution before merging" via Terraform. This setting must be configured manually through the GitHub UI:
1. Go to repository Settings > General > Pull Requests
2. Enable "Always suggest updating pull request branches"
3. Enable "Require conversation resolution before merging"

This limitation is noted in the Terraform configuration comments and may be addressed in future provider versions.

## Troubleshooting

### Common Issues

**Error: Resource already exists**
- Solution: Use `terraform import` to import existing resources

**Error: 401 Unauthorized**
- Solution: Verify `GITHUB_TOKEN` is set and has required scopes

**Error: 403 Forbidden**
- Solution: Token needs admin:org scope for organization-level resources

**Error: Team not found**
- Solution: Verify team slug is correct and team exists in organization

**Error: Status check not found**
- Solution: Ensure CI/CD workflows define the required status checks

## Contributing

When making changes to this configuration:

1. Create a feature branch
2. Make your changes
3. Run `terraform fmt` to format code
4. Run `terraform validate` to check syntax
5. Create a PR with a clear description of changes
6. Wait for review and approval
7. Apply changes to infrastructure after merge

## References

- [GitHub Provider Documentation](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Repository Resource](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository)
- [GitHub Repository Ruleset](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset)
- [GitHub Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Template Repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
