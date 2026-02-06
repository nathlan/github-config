# CI/CD Documentation

Comprehensive guides for managing the GitHub Terraform infrastructure CI/CD pipeline.

## 📚 Documentation Index

### Core Guides

1. **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Step-by-step deployment procedures
   - Initial setup and configuration
   - Standard deployment workflows
   - Environment configuration
   - Monitoring and verification
   - **Start here** for first-time setup

2. **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions
   - Quick diagnostics checklist
   - Authentication issues
   - Workflow failures
   - Terraform errors
   - Security scan issues
   - Debug mode instructions
   - **Use this** when encountering errors

3. **[ROLLBACK.md](./ROLLBACK.md)** - Rollback and recovery procedures
   - Emergency rollback process
   - Standard rollback workflows
   - Common rollback scenarios
   - Post-rollback verification
   - **Reference this** during incidents

## 🚀 Quick Start

### First Time Setup

```bash
# 1. Configure GitHub App credentials
gh variable set GH_CONFIG_APP_ID --body "your-app-id"
gh variable set GH_APP_INSTALLATION_ID --body "your-installation-id"
gh secret set GH_CONFIG_PRIVATE_KEY < private-key.pem

# 2. Create required environments
# Via GitHub UI: Settings → Environments → New environment
# - github-admin-plan (optional approval)
# - github-admin (required approval)

# 3. Test workflow
gh workflow run github-terraform.yml --ref main -f terraform_action=plan
```

See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

### Common Tasks

| Task | Command | Documentation |
|------|---------|---------------|
| Deploy changes | Create PR → Merge to main | [DEPLOYMENT.md](./DEPLOYMENT.md#deployment-process) |
| Rollback deployment | `git revert <commit>` | [ROLLBACK.md](./ROLLBACK.md#standard-rollback-process) |
| Debug workflow failure | `gh run view --log-failed` | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#workflow-failures) |
| Check drift | `gh run list --event=schedule` | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#drift-detection-issues) |
| Update configuration | Edit `terraform-configs/new-repository/` | [DEPLOYMENT.md](./DEPLOYMENT.md#deployment-process) |

## 🔍 Finding Information

### By Scenario

**Setting up for the first time?**
→ [DEPLOYMENT.md](./DEPLOYMENT.md#initial-setup)

**Workflow failing?**
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#quick-diagnostics)

**Need to revert changes?**
→ [ROLLBACK.md](./ROLLBACK.md#quick-rollback-emergency)

**Authentication issues?**
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#authentication-issues)

**Drift detected?**
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#drift-detection-issues)

**Security scan failing?**
→ [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#security-scan-issues)

### By Error Message

| Error | Guide | Section |
|-------|-------|---------|
| "Invalid GitHub App credentials" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-1-error-invalid-github-app-credentials) | Authentication |
| "Artifact not found" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-5-unable-to-download-artifact) | Workflow Failures |
| "Insufficient repository permissions" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-8-error-insufficient-repository-permissions) | Terraform Errors |
| "Checkov security violations" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-11-checkov-fails-with-security-violations) | Security Scans |
| "Repository already exists" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-9-error-repository-already-exists) | Terraform Errors |
| "Environment not found" | [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#issue-16-environment-not-found) | Environment Issues |

## 🏗️ CI/CD Architecture

### Workflow Overview

```
GitHub Provider Terraform CI/CD Pipeline
========================================

Triggers:
  • Push to main (terraform-configs/new-repository/**)
  • Pull request
  • Manual (workflow_dispatch)
  • Schedule (daily drift detection)

Jobs:
  1. ✅ Validate       - Format, validate, TFLint
  2. 🔒 Security       - Checkov scanning (fail-fast)
  3. 📝 Plan           - Generate plan, upload artifact
  4. 🚀 Apply          - Deploy with approval gate

Security Features:
  • All actions pinned to commit SHA
  • GitHub App token (auto-generated, fine-grained)
  • Manual approval required (github-admin environment)
  • Security scanning with Checkov (soft_fail: false)
  • Drift detection (daily at 8 AM UTC)
  • Plan artifact saved and reused (prevent drift)
```

### Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/github-terraform.yml` | Main workflow definition |
| `terraform-configs/new-repository/` | Terraform configuration |
| `.tflint.hcl` | TFLint configuration |
| `.checkov.yml` | Checkov security configuration |
| `docs/DEPLOYMENT.md` | Deployment guide (this directory) |
| `docs/TROUBLESHOOTING.md` | Troubleshooting guide |
| `docs/ROLLBACK.md` | Rollback procedures |

## 🔐 Security & Compliance

### Secrets & Variables

**Required Variables** (Settings → Secrets and variables → Actions):
- `GH_CONFIG_APP_ID` - GitHub App ID (variable)
- `GH_APP_INSTALLATION_ID` - Installation ID (variable)

**Required Secrets**:
- `GH_CONFIG_PRIVATE_KEY` - GitHub App private key PEM (secret)

**Required Environments** (Settings → Environments):
- `github-admin-plan` - Plan review (optional approval)
- `github-admin` - Production deployment (required approval)

### Security Best Practices

✅ **Implemented**:
- ✅ All GitHub Actions pinned to commit SHA (not tags)
- ✅ GitHub App authentication (fine-grained permissions)
- ✅ Security scanning with Checkov (fail on HIGH/CRITICAL)
- ✅ Code quality checks with TFLint
- ✅ Manual approval gates for production
- ✅ Plan artifacts saved (prevent apply drift)
- ✅ Drift detection (daily automated checks)
- ✅ Comprehensive audit trail

⚠️ **User Responsibilities**:
- Rotate GitHub App private keys periodically
- Review and approve deployments carefully
- Monitor drift detection issues
- Keep provider versions updated
- Review security scan results

## 📊 Monitoring & Observability

### Dashboard Locations

| Resource | URL | Purpose |
|----------|-----|---------|
| **Workflow Runs** | Actions tab | Execution history |
| **Security Alerts** | Security → Code scanning | Checkov findings |
| **Drift Issues** | Issues (label: drift-detection) | Automated reports |
| **Environments** | Settings → Environments | Approval history |
| **Deployments** | Deployments tab | Deployment timeline |

### Metrics to Monitor

- ✅ Workflow success rate
- ⏱️ Average deployment time
- 🔒 Security violations found/fixed
- 📈 Drift detection frequency
- ⏰ Time to rollback

## 🛠️ Maintenance

### Regular Tasks

**Daily**:
- Review drift detection results (automated)
- Monitor workflow runs for failures

**Weekly**:
- Review security scan findings
- Check for Terraform provider updates
- Review and close resolved drift issues

**Monthly**:
- Rotate GitHub App private keys (if policy requires)
- Review and update documentation
- Audit approval patterns
- Test rollback procedures

**Quarterly**:
- Update Terraform version
- Update GitHub provider version
- Review and update security baselines
- Conduct disaster recovery drill

## 🔄 Workflow States

### Pull Request Flow

```
PR Created
    ↓
Validate (fmt, validate, tflint)
    ↓
Security Scan (checkov)
    ↓
Plan (generate plan, comment on PR)
    ↓
[Waiting for Review]
    ↓
PR Approved & Merged
    ↓
[Continues to deployment flow]
```

### Deployment Flow

```
Push to main
    ↓
Validate
    ↓
Security Scan
    ↓
Plan (upload artifact)
    ↓
[Waiting for Approval - github-admin environment]
    ↓
Apply (use saved plan)
    ↓
Deployment Summary
```

### Drift Detection Flow

```
Daily Cron (8 AM UTC)
    ↓
Validate
    ↓
Security Scan
    ↓
Plan (detect drift)
    ↓
Drift Detected? ──No──> ✅ Log success
    ↓ Yes
Create Issue (drift-detection label)
    ↓
⚠️ Notify watchers
```

## 📞 Support & Resources

### Documentation

- [Terraform GitHub Provider Docs](https://registry.terraform.io/providers/integrations/github/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Checkov Documentation](https://www.checkov.io/)
- [TFLint Documentation](https://github.com/terraform-linters/tflint)

### Getting Help

1. **Check troubleshooting guide**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. **Search existing issues**: [GitHub Issues](https://github.com/nathlan/github-config/issues)
3. **Create new issue**: Provide workflow run URL, error message, recent changes
4. **Emergency contacts**: See [ROLLBACK.md](./ROLLBACK.md#emergency-contacts)

### Contributing

Found an issue or improvement? Please:

1. Search existing issues/PRs
2. Create issue describing the problem/enhancement
3. Submit PR with:
   - Clear description
   - Tests (if applicable)
   - Updated documentation

## 📝 Changelog

Track changes to CI/CD pipeline:

- **2024-02-06**: Initial workflow implementation
  - GitHub Provider Terraform workflow
  - Security scanning with Checkov
  - Drift detection with daily schedule
  - Comprehensive documentation

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub Terraform CI/CD - Quick Reference                   │
├─────────────────────────────────────────────────────────────┤
│  WORKFLOWS                                                   │
│  • github-terraform.yml - Main deployment workflow          │
│                                                              │
│  TRIGGERS                                                    │
│  • Push to main → Deploy with approval                      │
│  • Pull Request → Validate, scan, plan                      │
│  • Schedule (8AM UTC) → Drift detection                     │
│  • Manual → workflow_dispatch                               │
│                                                              │
│  ENVIRONMENTS                                                │
│  • github-admin-plan (optional) - Plan review               │
│  • github-admin (required) - Production deployment          │
│                                                              │
│  SECRETS/VARIABLES                                           │
│  • GH_CONFIG_APP_ID (var) - GitHub App ID                   │
│  • GH_APP_INSTALLATION_ID (var) - Installation ID           │
│  • GH_CONFIG_PRIVATE_KEY (secret) - Private key PEM         │
│                                                              │
│  COMMON COMMANDS                                             │
│  • gh run list --workflow=github-terraform.yml              │
│  • gh run view <id> --log-failed                            │
│  • gh workflow run github-terraform.yml                     │
│  • git revert <commit> && git push origin main              │
│                                                              │
│  DOCUMENTATION                                               │
│  • Setup: docs/DEPLOYMENT.md                                │
│  • Issues: docs/TROUBLESHOOTING.md                          │
│  • Rollback: docs/ROLLBACK.md                               │
└─────────────────────────────────────────────────────────────┘
```

---

**Need immediate help?** Start with [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#quick-diagnostics)
