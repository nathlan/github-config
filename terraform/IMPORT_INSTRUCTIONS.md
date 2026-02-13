# Import Instructions for alz-workload-template

## Overview

The `alz-workload-template` repository **ALREADY EXISTS** in GitHub. This Terraform configuration will import and manage the existing repository, specifically to set `is_template = true`.

## Critical: Import Before Apply

⚠️ **You MUST import the existing repository into Terraform state before running `terraform apply`.**

If you skip the import step, Terraform will try to create a new repository, which will fail because the repository already exists.

## Step 1: Import Existing Repository

From the `terraform/` directory in the `github-config` repository:

```bash
cd terraform/
terraform import github_repository.alz_workload_template alz-workload-template
```

**Expected Output:**
```
github_repository.alz_workload_template: Importing from ID "alz-workload-template"...
github_repository.alz_workload_template: Import prepared!
  Prepared github_repository for import
github_repository.alz_workload_template: Refreshing state... [id=alz-workload-template]

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.
```

## Step 2: Verify Import

Check that the repository is now in Terraform state:

```bash
terraform state show github_repository.alz_workload_template
```

**Expected Output:** Should show current repository configuration including `is_template = false` (or not set).

## Step 3: Review Planned Changes

Run a plan to see what Terraform will change:

```bash
terraform plan -var="github_organization=nathlan"
```

**Expected Changes:**
- **is_template:** `false → true` ⭐ (the critical change)
- Possibly other minor settings to align with Terraform configuration

**Example Output:**
```
Terraform will perform the following actions:

  # github_repository.alz_workload_template will be updated in-place
  ~ resource "github_repository" "alz_workload_template" {
        id          = "alz-workload-template"
      ~ is_template = false -> true
        name        = "alz-workload-template"
        # (other attributes remain unchanged)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

## Step 4: Apply Configuration

Apply the changes to set `is_template = true`:

```bash
terraform apply -var="github_organization=nathlan"
```

Type `yes` when prompted to confirm.

**Expected Output:**
```
github_repository.alz_workload_template: Modifying... [id=alz-workload-template]
github_repository.alz_workload_template: Modifications complete after 2s [id=alz-workload-template]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

## Step 5: Verify in GitHub UI

1. **Visit Repository:**
   - Navigate to: https://github.com/nathlan/alz-workload-template

2. **Check Template Button:**
   - Look for green "Use this template" button near top-right
   - Button should now be visible

3. **Test Template Functionality:**
   - Click "Use this template" → "Create a new repository"
   - Name it: `test-template-verification-{timestamp}`
   - Verify all files from template are copied
   - Delete the test repository after verification

## Step 6: Verify Terraform State

Confirm the setting in Terraform state:

```bash
terraform state show github_repository.alz_workload_template | grep is_template
```

**Expected Output:**
```
is_template = true
```

## Common Issues

### Import Fails with "Resource Not Found"

**Error:**
```
Error: Cannot import non-existent remote object
```

**Solution:**
- Verify repository name is exactly `alz-workload-template`
- Check you're authenticated to the correct organization
- Ensure `GITHUB_TOKEN` has appropriate permissions

### Import Fails with "Permission Denied"

**Error:**
```
Error: GET https://api.github.com/repos/nathlan/alz-workload-template: 403 Forbidden
```

**Solution:**
- Verify `GITHUB_TOKEN` has `repo` and `admin:org` scopes
- Ensure you have admin access to the repository
- Check token hasn't expired

### Plan Shows Many Unexpected Changes

**Issue:** After import, `terraform plan` shows many changes beyond `is_template`.

**Solution:**
- This is normal if current repository settings differ from Terraform config
- Review each change to ensure it's acceptable
- If needed, adjust Terraform config to match current state
- Focus on the critical change: `is_template = true`

### Apply Shows "already exists" Error

**Error:**
```
Error: repository "alz-workload-template" already exists
```

**Solution:**
- You skipped the import step
- Run the import command from Step 1
- Then run `terraform plan` and `terraform apply`

## What This Import Does

### What Changes:
- ✅ Repository is added to Terraform state
- ✅ Terraform now manages this repository
- ✅ Setting `is_template = true` is applied
- ✅ Repository settings align with Terraform config

### What Doesn't Change:
- ❌ Repository name (stays `alz-workload-template`)
- ❌ Repository content (files, branches, history)
- ❌ Issues, PRs, or other repository data
- ❌ Team access or collaborators (managed separately)

## Summary

```bash
# Complete workflow:
cd terraform/

# 1. Import existing repository
terraform import github_repository.alz_workload_template alz-workload-template

# 2. Review changes
terraform plan -var="github_organization=nathlan"

# 3. Apply configuration
terraform apply -var="github_organization=nathlan"

# 4. Verify
terraform state show github_repository.alz_workload_template | grep is_template
# Should output: is_template = true

# 5. Check GitHub UI
open https://github.com/nathlan/alz-workload-template
# Verify "Use this template" button appears
```

---

**Key Point:** This is an **import and configure** operation, not a create operation. The repository already exists and will continue to exist with the same content, history, and data. Only the `is_template` setting (and possibly minor alignment settings) will change.
