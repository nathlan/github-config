# ALZ Workload Template - Terraform Configuration Handover

## Purpose
This Terraform configuration manages the GitHub repository settings for `nathlan/alz-workload-template`, which serves as a template repository for ALZ workload deployments.

## Context for CI/CD Agent

### Repository Purpose
The `alz-workload-template` repository is a **GitHub template repository** that provides:
- Pre-configured Terraform workflows for Azure Landing Zone workloads
- Standard directory structure for workload repositories
- Child workflows that call parent reusable workflows from `nathlan/.github-workflows`
- README template for workload documentation

### Configuration Highlights

**Critical Setting**: `is_template = true`
- This flag enables the "Use this template" button on GitHub
- Allows teams to create new workload repositories from this template
- Essential for the ALZ self-service vending pattern

**Branch Protection Strategy**:
- Uses modern `github_repository_ruleset` for most protection rules
- Falls back to legacy `github_branch_protection_v3` for push restrictions
  - Reason: GitHub's ruleset API doesn't fully support push restrictions yet
  - This dual approach ensures complete protection coverage

**Required Status Checks**: `["validate", "security", "plan"]`
- These must exist in the repository's CI/CD workflows
- If workflows change, update the `required_status_checks` variable

**Team Access**:
- `platform-engineering` team has maintain access
- Same team has push allowance to main branch (for emergency fixes)

### Integration with CI/CD Workflows

If you're working with the `cicd-workflow` agent to generate GitHub Actions workflows:

1. **Ensure Status Check Names Match**: The workflows must define jobs with these names:
   - `validate`
   - `security`
   - `plan`

2. **Workflow Location**: Workflows should be in `.github/workflows/`

3. **Branch Triggers**: Main branch protection applies, so PRs are required

4. **Template Repository Workflow**: When someone uses this template:
   - GitHub creates a new repository from this template
   - All files (including `.github/workflows/`) are copied
   - The new repository inherits the workflow structure
   - Teams only need to configure secrets/variables

### State Management Considerations

**Current State**: Local state in `/terraform` directory
- `.tfstate` files are gitignored
- Suitable for initial setup and small teams

**Production Recommendation**: Migrate to remote state
- Options: Terraform Cloud, S3 + DynamoDB, Azure Blob Storage
- Enables team collaboration and state locking
- Provides state history and rollback capability

## For Future Maintenance

### Adding New Required Checks
Update `variables.tf`:
```hcl
variable "required_status_checks" {
  default = ["validate", "security", "plan", "new-check"]
}
```

### Modifying Branch Protection
Edit `main.tf` in the `github_repository_ruleset` resource

### Changing Team Access
Update `variables.tf`:
```hcl
variable "team_maintainers" {
  default = ["platform-engineering", "new-team"]
}
```

## Import Strategy

If the repository already exists (which it does), you'll need to import:

```bash
# Import repository
terraform import github_repository.alz_workload_template alz-workload-template

# Import team access (after getting team ID)
terraform import 'github_team_repository.maintainers["platform-engineering"]' TEAM_ID:alz-workload-template

# Import repository settings (if resource exists)
terraform import github_repository_settings.alz_workload_template alz-workload-template
```

**Note**: Branch protection resources (rulesets and v3 protection) can be imported similarly if they already exist.

## Risk Assessment

**Overall Risk**: 🟡 Medium

**Why Medium?**
- Modifies existing repository configuration
- Changes branch protection rules that affect developer workflow
- Potential to lock out team members if team references are incorrect
- No data loss risk, but workflow disruption possible

**Mitigation**:
- All changes go through PR review
- Test plan shows exactly what will change
- Administrators can bypass branch protection if needed
- Template flag changes are non-destructive

## Validation Checklist

Before applying this configuration:
- [ ] Verify `platform-engineering` team exists in the organization
- [ ] Confirm team slug is correct (not display name)
- [ ] Check that required status checks exist in workflows
- [ ] Review current branch protection settings
- [ ] Ensure GITHUB_TOKEN has admin:org scope
- [ ] Run `terraform plan` and review all changes
- [ ] Confirm with team that protection rules are acceptable

## Dependencies

### Upstream
- GitHub organization: `nathlan` must exist
- Team: `platform-engineering` must exist
- Repository: `alz-workload-template` already exists

### Downstream
- Workload repositories created from this template
- CI/CD workflows in the template repository
- Documentation and scripts that reference this configuration

## Related Documentation

- Main README: `/tmp/gh-config-20260210-042444/terraform/README.md`
- ALZ Implementation: `/home/runner/work/.github-private/.github-private/ALZ_IMPLEMENTATION_INSTRUCTIONS.md`
- Workflow Implementation: `/home/runner/work/.github-private/.github-private/WORKFLOW_IMPLEMENTATION_SUMMARY.md`
