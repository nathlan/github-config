# Rollback Procedures - GitHub Terraform Infrastructure

This guide provides procedures for rolling back infrastructure changes deployed via Terraform when issues are detected.

## Table of Contents

1. [Overview](#overview)
2. [Quick Rollback (Emergency)](#quick-rollback-emergency)
3. [Standard Rollback Process](#standard-rollback-process)
4. [Rollback Strategies](#rollback-strategies)
5. [Common Rollback Scenarios](#common-rollback-scenarios)
6. [Verification & Testing](#verification--testing)
7. [Post-Rollback Actions](#post-rollback-actions)

---

## Overview

### When to Rollback

Consider rollback when:
- ❌ Deployed resources cause production issues
- ❌ Security vulnerabilities discovered post-deployment
- ❌ Incorrect configuration causes service disruption
- ❌ Resource dependencies break existing systems
- ❌ Cost concerns from misconfigured resources

### Rollback Methods

| Method | Speed | Risk | Use Case |
|--------|-------|------|----------|
| **Git Revert** | Fast (5-10 min) | Low | Most scenarios - preferred method |
| **Terraform Destroy** | Medium (10-20 min) | Medium | Remove specific resources |
| **Manual Changes** | Immediate | High | Emergency only - requires follow-up |
| **State Manipulation** | Slow (20-30 min) | High | Complex scenarios - last resort |

---

## Quick Rollback (Emergency)

**⚠️ Use this process when immediate action is required to restore service**

### Step 1: Assess Situation (2 minutes)

```bash
# Identify the problematic workflow run
gh run list --workflow=github-terraform.yml --limit 5

# View the last deployment
gh run view <run-id>
```

Questions to answer:
- What broke? (Repository settings? Branch protection? Access?)
- When did it happen? (Last workflow run?)
- What resources were changed? (Check plan output)

### Step 2: Stop Ongoing Deployments (1 minute)

```bash
# Cancel any running workflows
gh run list --workflow=github-terraform.yml --status=in_progress --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}
```

Or via GitHub UI:
- Actions tab → Running workflows → Cancel workflow

### Step 3: Emergency Manual Fix (5 minutes)

**⚠️ Only if critical service impact - requires follow-up Terraform update**

Navigate to GitHub UI and manually revert:

**Example: Revert branch protection change**
```
1. Go to: github.com/nathlan/<repo>/settings/rules
2. Edit affected ruleset
3. Restore previous settings
4. Save changes
```

**Example: Restore repository settings**
```
1. Go to: github.com/nathlan/<repo>/settings
2. Revert changed settings:
   - Visibility
   - Features (Issues, Wiki, Projects)
   - Merge settings
3. Save changes
```

### Step 4: Git Revert (10 minutes)

```bash
# Clone repository
git clone https://github.com/nathlan/github-config.git
cd github-config

# Identify problem commit
git log --oneline --graph --decorate -10

# Revert the problematic commit
git revert <commit-sha> --no-edit

# Push revert commit
git push origin main
```

The CI/CD workflow will:
- ✅ Validate reverted configuration
- ✅ Run security scans
- ✅ Generate plan showing reversion
- ⏸️ Wait for approval
- ✅ Apply rollback

### Step 5: Verify Rollback (5 minutes)

```bash
# Monitor workflow execution
gh run watch

# Verify resources restored
# (See Verification section below)
```

---

## Standard Rollback Process

**Use this process for non-emergency rollbacks with proper review**

### Phase 1: Preparation

#### 1. Identify Target State

Determine which commit/state to rollback to:

```bash
# View recent changes
git log --oneline --graph --all -20 -- terraform-configs/new-repository/

# View specific commit details
git show <commit-sha>

# View changes made
git diff <good-commit-sha> <bad-commit-sha> -- terraform-configs/new-repository/
```

#### 2. Create Rollback Branch

```bash
# Create branch from current main
git checkout main
git pull origin main
git checkout -b rollback/revert-<issue-description>
```

#### 3. Review Current State

```bash
# Check current Terraform state (if accessible)
cd terraform-configs/new-repository

# View what's currently deployed
terraform show

# Or view latest workflow run output
gh run view --log
```

### Phase 2: Execute Rollback

#### Option A: Git Revert (Recommended)

```bash
# Revert specific commit
git revert <commit-sha> --no-edit

# Or revert multiple commits
git revert <oldest-bad-commit>..<newest-bad-commit> --no-edit

# Or revert to specific state
git revert --no-commit <bad-commit-1> <bad-commit-2>
git commit -m "rollback: revert to working state before issue"
```

#### Option B: Manual Configuration Restore

```bash
# Edit Terraform files to match previous state
cd terraform-configs/new-repository

# Restore from known-good commit
git show <good-commit-sha>:terraform-configs/new-repository/main.tf > main.tf
git show <good-commit-sha>:terraform-configs/new-repository/variables.tf > variables.tf

# Verify changes
git diff

# Commit restored configuration
git add .
git commit -m "rollback: restore configuration to working state"
```

### Phase 3: Test & Validate

#### 1. Local Validation

```bash
# Format check
terraform fmt -check -recursive

# Validate configuration
terraform init -backend=false
terraform validate

# Generate plan (requires credentials)
export GITHUB_APP_ID="your-app-id"
export GITHUB_APP_INSTALLATION_ID="your-installation-id"
export GITHUB_APP_PEM_FILE="$(cat path-to-private-key.pem)"

terraform plan -var="github_organization=nathlan"
```

#### 2. Create Pull Request

```bash
# Push rollback branch
git push origin rollback/revert-<issue-description>

# Create PR
gh pr create \
  --title "🔄 Rollback: Revert to working configuration" \
  --body "## Rollback Details

**Issue**: [Describe what broke]
**Root Cause**: [Why it broke]
**Reverting**: [Commit SHAs being reverted]
**Expected Outcome**: [What should be restored]

## Verification
- [ ] Terraform validation passes
- [ ] Security scan passes
- [ ] Plan shows expected reversions
- [ ] Tested locally (if possible)

## Rollback Impact
[Describe what resources will be changed back]

See: [ROLLBACK.md](./docs/ROLLBACK.md)" \
  --label "rollback,urgent"
```

#### 3. Review Workflow Output

Wait for automated checks:
- ✅ Validation job passes
- ✅ Security scan passes
- 📝 Plan shows rollback changes
- Review PR comment with plan output

### Phase 4: Deploy Rollback

#### 1. Approve PR

- **Review plan carefully**: Ensure it reverts to expected state
- **Check security scan**: No new issues introduced
- **Get required approvals**: Follow standard approval process

#### 2. Merge PR

```bash
# Merge PR (or via GitHub UI)
gh pr merge --squash --delete-branch
```

#### 3. Monitor Deployment

```bash
# Watch workflow execution
gh run watch

# View logs in real-time
gh run view --log-failed
```

#### 4. Approve Production Deployment

- Workflow will pause at `github-admin` environment
- Review plan output one final time
- Approve deployment in GitHub UI:
  - Actions tab → Select workflow run → Review deployments → Approve

---

## Rollback Strategies

### Strategy 1: Revert Last Commit

**When**: Single bad commit on main

```bash
git revert HEAD --no-edit
git push origin main
```

**Pros**: Simple, preserves history
**Cons**: Creates new commit

### Strategy 2: Revert Range of Commits

**When**: Multiple problematic commits

```bash
# Revert commits from newest to oldest
git revert --no-commit <oldest-bad>^..<newest-bad>
git commit -m "rollback: revert problematic changes"
git push origin main
```

**Pros**: Reverts multiple commits at once
**Cons**: Potential merge conflicts

### Strategy 3: Restore from Known-Good Commit

**When**: Complex changes, easier to restore than revert

```bash
# Copy files from good commit
git show <good-commit>:terraform-configs/new-repository/main.tf > main.tf

# Commit restored files
git add .
git commit -m "rollback: restore to working configuration"
git push origin main
```

**Pros**: Clean restoration
**Cons**: Loses commit history granularity

### Strategy 4: Terraform Destroy + Recreate

**When**: Resources corrupted, easier to recreate

```bash
# Destroy specific resources
terraform destroy -target=github_repository.repo

# Or destroy all resources
terraform destroy -var="github_organization=nathlan"

# Then reapply from good configuration
git checkout <good-commit>
terraform apply -var="github_organization=nathlan"
```

**⚠️ Use with extreme caution**: Permanently deletes resources

---

## Common Rollback Scenarios

### Scenario 1: Incorrect Repository Settings

**Problem**: Repository visibility or settings misconfigured

**Rollback**:
```bash
# Immediate: Fix in GitHub UI
# Settings → Change visibility/settings → Save

# Then: Update Terraform to match
git checkout -b fix/correct-repo-settings
# Edit terraform-configs/new-repository/terraform.tfvars or main.tf
git commit -am "fix: correct repository settings"
git push origin fix/correct-repo-settings
# Create PR and follow standard deployment
```

### Scenario 2: Branch Protection Too Restrictive

**Problem**: Branch protection prevents merges/pushes

**Rollback**:
```bash
# Immediate: Adjust in GitHub UI
# Settings → Rules → Edit ruleset → Reduce restrictions

# Then: Revert Terraform change
git revert <commit-sha>
git push origin main
```

### Scenario 3: Actions Permissions Broken

**Problem**: GitHub Actions can't create PRs or access resources

**Rollback**:
```bash
# Immediate: Fix in GitHub UI
# Settings → Actions → General → Workflow permissions → Adjust

# Then: Rollback Terraform
git revert <commit-sha>
git push origin main
```

### Scenario 4: Wrong Organization Target

**Problem**: Deployed to wrong GitHub organization

**⚠️ Critical**: Requires immediate action

**Rollback**:
```bash
# 1. Destroy resources in wrong org (manually via UI or Terraform)
terraform destroy -var="github_organization=wrong-org"

# 2. Revert configuration change
git revert <commit-sha>
git push origin main

# 3. Verify correct org in workflow
grep "GITHUB_ORGANIZATION" .github/workflows/github-terraform.yml
```

### Scenario 5: Drift Detected After Manual Changes

**Problem**: Manual changes conflict with Terraform

**Options**:

**A. Accept Manual Changes (Update Terraform)**
```bash
# Import manual changes into Terraform
terraform import github_repository.repo <repo-name>

# Update configuration to match
# Edit main.tf to reflect current state

# Plan and apply
terraform plan -var="github_organization=nathlan"
terraform apply -var="github_organization=nathlan"
```

**B. Revert Manual Changes (Reapply Terraform)**
```bash
# Workflow automatically applies on schedule (drift detection)
# Or manually trigger workflow:
gh workflow run github-terraform.yml --ref main
```

---

## Verification & Testing

### Post-Rollback Verification Checklist

After rollback deployment completes:

```bash
# 1. Verify workflow succeeded
gh run view --log

# 2. Check resource state
gh repo view nathlan/<repo-name>

# 3. Verify branch protection
gh api repos/nathlan/<repo-name>/rulesets

# 4. Test Actions permissions
# Create test PR or manual workflow trigger

# 5. Verify no drift
# Wait for next scheduled drift detection or:
gh workflow run github-terraform.yml --ref main -f terraform_action=plan
```

#### Detailed Verification Steps

| Resource | Verification Method | Expected State |
|----------|-------------------|----------------|
| **Repository** | `gh repo view nathlan/<repo-name>` | Matches rolled-back config |
| **Visibility** | GitHub UI → Settings | Private/Public as configured |
| **Branch Protection** | Settings → Rules | Ruleset active with correct settings |
| **Actions Permissions** | Settings → Actions → General | Correct workflow permissions |
| **Topics** | Repository page | Correct topics applied |
| **Vulnerabilities** | Security tab | Alerts enabled |

### Testing Rollback (Pre-Production)

**Best Practice**: Test rollback procedures in non-production before relying on them

```bash
# 1. Create test repository configuration
cp -r terraform-configs/new-repository terraform-configs/test-rollback

# 2. Deploy test configuration
# Update workflow to use test-rollback directory

# 3. Make intentional "breaking" change
# Edit test configuration

# 4. Deploy breaking change
# Commit and push

# 5. Practice rollback
git revert HEAD
git push origin main

# 6. Verify rollback worked
# Check test resources restored

# 7. Clean up
terraform destroy -var="github_organization=nathlan"
```

---

## Post-Rollback Actions

### Immediate (Within 1 hour)

- [ ] **Verify rollback successful**: Check all resources restored
- [ ] **Update incident tracker**: Document what happened
- [ ] **Notify stakeholders**: Team members, dependent services
- [ ] **Monitor for side effects**: Watch for related issues

### Short-term (Within 24 hours)

- [ ] **Root cause analysis**: Why did the issue occur?
- [ ] **Document lessons learned**: Update troubleshooting guide
- [ ] **Fix underlying issue**: Address root cause in new PR
- [ ] **Update tests**: Add test cases to prevent recurrence
- [ ] **Review approval process**: Was review adequate?

### Long-term (Within 1 week)

- [ ] **Improve validation**: Add checks to catch similar issues
- [ ] **Update documentation**: Reflect new learnings
- [ ] **Train team**: Share rollback experience
- [ ] **Review CI/CD pipeline**: Strengthen safeguards
- [ ] **Consider policy changes**: Update approval requirements

### Incident Report Template

```markdown
# Rollback Incident Report

## Incident Details
- **Date**: YYYY-MM-DD HH:MM UTC
- **Duration**: X hours
- **Severity**: Critical/High/Medium/Low
- **Affected Resources**: [List resources]

## Timeline
- HH:MM - Deployment started
- HH:MM - Issue detected
- HH:MM - Rollback initiated
- HH:MM - Rollback completed
- HH:MM - Verification done

## Root Cause
[Detailed explanation of what went wrong]

## Impact
- Services affected: [List]
- Users impacted: [Estimate]
- Data loss: Yes/No
- Downtime: X minutes

## Resolution
[How was it fixed/rolled back]

## Prevention
- [ ] Add validation rule: [Specific rule]
- [ ] Update documentation: [What to add]
- [ ] Improve testing: [New test case]
- [ ] Process change: [What to change]

## Lessons Learned
1. [Lesson 1]
2. [Lesson 2]
3. [Lesson 3]
```

---

## Emergency Contacts

When rollback fails or escalation needed:

- **GitHub Support**: https://support.github.com
- **Terraform Support**: https://support.hashicorp.com
- **Team Lead**: [Name/Contact]
- **On-Call Engineer**: [Contact method]

---

## Related Documentation

- [Deployment Guide](./DEPLOYMENT.md) - Standard deployment procedures
- [Troubleshooting Guide](./TROUBLESHOOTING.md) - Common issues and solutions
- [Token Permissions](../terraform-configs/new-repository/TOKEN_PERMISSIONS.md) - GitHub App setup

---

## Rollback Decision Flowchart

```
                     ┌─────────────────┐
                     │  Issue Detected │
                     └────────┬────────┘
                              │
                    ┌─────────▼──────────┐
                    │ Critical/Emergency?│
                    └─────────┬──────────┘
                     Yes ◄────┤───► No
                     │                 │
          ┌──────────▼─────────┐      │
          │ Emergency Rollback  │      │
          │  (Manual + Git)     │      │
          └──────────┬─────────┘      │
                     │                 │
                     │        ┌────────▼────────┐
                     │        │ Standard Process│
                     │        │ (PR + Review)   │
                     │        └────────┬────────┘
                     │                 │
                 ┌───▼─────────────────▼────┐
                 │   Deploy Rollback via    │
                 │      CI/CD Workflow       │
                 └───────────┬───────────────┘
                             │
                      ┌──────▼───────┐
                      │   Verify     │
                      │   Success    │
                      └──────┬───────┘
                             │
                    ┌────────▼─────────┐
                    │ Post-Rollback    │
                    │    Actions       │
                    └──────────────────┘
```

---

**Remember**: A rollback is a recovery mechanism, not a solution. Always follow up with root cause analysis and permanent fixes.
