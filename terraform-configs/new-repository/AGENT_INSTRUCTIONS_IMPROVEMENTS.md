# GitHub Configuration Agent - Process Improvements

This document captures refinements and improvements to the GitHub Configuration Agent workflow based on real-world usage and lessons learned.

## Enhanced Discovery Phase

### Use GitHub MCP Server for Documentation Search

**New Step: Search GitHub Documentation Before Provider Research**

When discovering GitHub features or configurations to implement, use the GitHub MCP server to search official GitHub documentation. This helps ensure you understand GitHub's native features before mapping them to Terraform resources.

**Tool**: `github-mcp-server-github_support_docs_search`

**When to use:**
- Understanding GitHub features mentioned in requirements (e.g., "Copilot agent firewall", "branch protection")
- Clarifying GitHub terminology and capabilities
- Finding official GitHub settings and configuration options
- Understanding GitHub Actions and workflow permissions
- Learning about security features and best practices

**Example workflow:**

1. **User Request**: "Configure Copilot agent firewall allowlist"

2. **Search GitHub Docs First**:
   ```
   github_support_docs_search("GitHub Copilot agent firewall allowlist configuration")
   ```
   
3. **Learn from Results**:
   - Discover that it uses `COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS` variable
   - Understand it extends (not replaces) default allowlist
   - Learn about default allowed domains
   - Find security considerations

4. **Then Search Terraform Provider**:
   ```
   terraform-search_providers(service_slug="actions", provider_document_type="resources")
   terraform-get_provider_details(provider_doc_id="11382444") # actions_variable
   ```

5. **Map GitHub Feature to Terraform**:
   - GitHub feature: Repository variable
   - Terraform resource: `github_actions_variable`
   - Configuration: Set variable name and comma-separated values

**Benefits:**
- ✅ Accurate understanding of GitHub features
- ✅ Discover GitHub-native limitations and requirements
- ✅ Learn correct terminology and parameter formats
- ✅ Find related features you might have missed
- ✅ Better security awareness

## Improved Research Pattern

### Updated Phase 1: Discovery

**Old approach:**
1. Parse requirements
2. Search Terraform provider
3. Generate code

**New approach:**
1. Parse requirements
2. **Search GitHub documentation for features mentioned** ⭐ NEW
3. Understand GitHub's native implementation
4. Search Terraform provider for corresponding resources
5. Map GitHub features to Terraform resources
6. Generate code with accurate configuration

### Example: Branch Protection

**Requirement**: "Add simple branch policies on main"

**Step 1: Search GitHub Docs**
```
github_support_docs_search("branch protection rules best practices")
```
Learn:
- Modern approach uses Repository Rulesets (not legacy branch protection)
- Rulesets support targeting, enforcement modes, and bypass actors
- Can apply to branches, tags, or push events
- Difference between ruleset enforcement modes: active, disabled, evaluate

**Step 2: Search Terraform**
```
terraform-search_providers(service_slug="repository", provider_document_type="resources")
```
Find: `github_repository_ruleset` resource

**Step 3: Map and Generate**
Create configuration using `github_repository_ruleset` with:
- `target = "branch"`
- `enforcement = "active"`
- `conditions.ref_name.include = ["refs/heads/main"]`
- Appropriate rules for protection

## Common GitHub → Terraform Mappings

Based on this workflow, here are common mappings discovered:

| GitHub Feature | GitHub Docs Search Term | Terraform Resource |
|----------------|------------------------|-------------------|
| Branch protection | "branch protection rules" | `github_repository_ruleset` |
| Copilot firewall | "copilot agent firewall allowlist" | `github_actions_variable` (variable name: `COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS`) |
| Actions permissions | "github actions permissions repository" | `github_actions_repository_permissions` |
| PR creation from Actions | "github actions create pull request token permissions" | `github_workflow_repository_permissions` with `can_approve_pull_request_reviews` |
| Repository variables | "github actions variables" | `github_actions_variable` |
| Repository secrets | "github actions secrets" | `github_actions_secret` |
| Deploy keys | "deploy keys ssh" | `github_repository_deploy_key` |
| Webhooks | "repository webhooks" | `github_repository_webhook` |
| Team access | "manage team repository access" | `github_team_repository` |

## Additional Process Refinements

### 1. Validation Improvements

**Always run these checks in order:**

```bash
# 1. Format check and auto-fix
terraform fmt -recursive

# 2. Validation
terraform validate

# 3. Security scan
grep -r "token\s*=\s*[\"']" . --include="*.tf"
grep -r "password\s*=\s*[\"']" . --include="*.tf"

# 4. Optional: Plan (requires valid token)
terraform plan -var="github_organization=org"
```

### 2. Documentation Standards

**Every configuration should include:**

- ✅ `README.md` with:
  - Resources managed
  - Prerequisites and permissions
  - Usage instructions with examples
  - Security considerations
  - Troubleshooting section
  - References to GitHub docs

- ✅ `TOKEN_PERMISSIONS.md` with:
  - Exact permissions needed
  - Multiple auth options (PAT classic, fine-grained, GitHub App)
  - How to verify permissions
  - Security best practices

- ✅ `terraform.tfvars.example` with:
  - All variables documented
  - Realistic example values
  - Explanatory comments

### 3. Variable Design Patterns

**Use these patterns consistently:**

```hcl
# Always validate organization name
variable "github_organization" {
  description = "The GitHub organization name"
  type        = string
  validation {
    condition     = length(var.github_organization) > 0
    error_message = "The github_organization value must not be empty."
  }
}

# Use lists for multi-value configs
variable "copilot_firewall_allowlist" {
  description = "Additional domains to add to the Copilot agent firewall allowlist"
  type        = list(string)
  default     = []
}

# Use enums for fixed options
variable "repository_visibility" {
  description = "The visibility of the repository"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "internal"], var.repository_visibility)
    error_message = "Repository visibility must be one of: public, private, or internal."
  }
}

# Use bools for feature flags
variable "enable_feature" {
  description = "Enable the feature"
  type        = bool
  default     = true
}
```

### 4. Resource Naming Conventions

**Follow these patterns:**

```hcl
# Main resource: use singular descriptive name
resource "github_repository" "repo" { }

# Related resources: use same base name
resource "github_actions_repository_permissions" "repo" { }
resource "github_workflow_repository_permissions" "repo" { }

# Multiple similar resources: use descriptive suffixes
resource "github_repository_ruleset" "main_branch_protection" { }
resource "github_repository_ruleset" "release_branch_protection" { }

# Data sources: prefix with data type
data "github_organization" "org" { }
data "github_team" "existing_team" { }
```

### 5. Security Review Checklist

Before creating PR, verify:

- [ ] No hardcoded tokens, passwords, or API keys
- [ ] All sensitive values use variables or environment variables
- [ ] Variables have validation rules where applicable
- [ ] Token permissions documented clearly
- [ ] Destructive operations flagged in README
- [ ] `.gitignore` includes `*.tfvars` and `*.tfstate`
- [ ] Comments explain non-obvious logic
- [ ] Lifecycle blocks for critical resources (if needed)

### 6. PR Description Template

Use this template for consistency:

```markdown
## Summary
Brief description of what this Terraform configuration manages

## Resources Managed
- Resource 1: Description
- Resource 2: Description
- ...

## Operations Impact
- 🟢 Creates: List new resources
- 🟡 Modifies: List modifications (if any)
- 🔴 Deletes: List deletions (if any)

## Prerequisites
1. GitHub token with permissions (see TOKEN_PERMISSIONS.md)
2. Terraform >= 1.9.0
3. Access to organization/repository

## Testing Steps
1. Set GITHUB_TOKEN environment variable
2. Run `terraform init`
3. Run `terraform plan -var="github_organization=your-org"`
4. Review plan output carefully
5. Run `terraform apply` if plan looks correct

## Security Considerations
- List any security-relevant configurations
- Flag any elevated permissions
- Note any destructive operations

## Risk Level
🟢 Low / 🟡 Medium / 🔴 High

## References
- Link to GitHub documentation
- Link to Terraform provider docs
- Related issues/PRs
```

## Tools Usage Summary

**Recommended tool call sequence for GitHub configuration tasks:**

1. `github-mcp-server-get_me` - Identify authenticated user
2. `github-mcp-server-github_support_docs_search` - Search GitHub docs for features ⭐ **NEW**
3. `terraform-get_latest_provider_version` - Get latest provider version
4. `terraform-search_providers` - Search for relevant resources
5. `terraform-get_provider_details` - Get detailed resource documentation
6. `github-mcp-server-get_organization` or similar - Verify target exists (if needed)
7. Generate configuration in `/tmp/gh-config-<timestamp>/`
8. Validate and test
9. Create PR with files

## Quick Reference: GitHub Docs Search Topics

**Common search queries for GitHub features:**

- Branch protection: `"branch protection rules and rulesets"`
- Actions permissions: `"github actions repository permissions"`
- Workflow permissions: `"github actions workflow permissions GITHUB_TOKEN"`
- Copilot: `"github copilot agent firewall" or "copilot code review"`
- Secrets management: `"github actions secrets variables"`
- Deploy keys: `"deploy keys ssh access"`
- Webhooks: `"webhooks events payloads"`
- Security: `"dependabot vulnerability alerts security"`
- Teams: `"manage team repository access permissions"`
- Environments: `"deployment environments protection rules"`

## Integration with Existing Workflow

This enhancement integrates into the existing agent workflow at **Phase 1: Discovery, Step 2**:

```
Phase 1: Discovery
├─ Step 1: Understand Intent
├─ Step 2: Discover State
│  ├─ 2a: Search GitHub documentation (NEW) ⭐
│  ├─ 2b: Use GitHub MCP read-only tools
│  └─ 2c: Verify resources exist
├─ Step 3: Research Provider
│  ├─ 3a: Get latest version
│  ├─ 3b: Search for resources
│  └─ 3c: Get detailed docs
└─ Step 4: Map GitHub features to Terraform
```

## Conclusion

By searching GitHub documentation first, we ensure our Terraform configurations accurately implement GitHub's features as intended, with proper understanding of limitations, best practices, and security implications. This leads to higher quality infrastructure-as-code that truly represents GitHub's capabilities.

---

**Last Updated**: 2026-02-06  
**Version**: 1.1.0
