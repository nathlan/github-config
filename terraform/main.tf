# ============================================================================
# Repository Configuration
# ============================================================================
# Manages the alz-workload-template repository settings
# This is a template repository used for creating new ALZ workload repositories

resource "github_repository" "alz_workload_template" {
  name        = var.repository_name
  description = var.repository_description
  visibility  = var.repository_visibility

  # Template repository flag - CRITICAL for enabling "Use this template" button
  is_template = true

  # Repository topics for discoverability
  topics = var.repository_topics

  # Feature toggles
  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  # Merge settings
  allow_squash_merge = true
  allow_merge_commit = false
  allow_rebase_merge = true

  # Automatically delete head branches after PRs are merged
  delete_branch_on_merge = true

  # Squash merge commit settings
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"

  # Prevent accidental deletion of this critical template repository
  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================================
# Branch Protection Rules
# ============================================================================
# Implements branch protection for main branch using modern ruleset approach
# Requires PR reviews, status checks, and restricts push access

resource "github_repository_ruleset" "main_branch_protection" {
  name        = "Main Branch Protection"
  repository  = github_repository.alz_workload_template.name
  target      = "branch"
  enforcement = "active"

  # Apply ruleset to main branch only
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Branch protection rules
  rules {
    # Require pull request before merging
    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
      require_code_owner_review       = false
      require_last_push_approval      = false
    }

    # Require status checks to pass
    required_status_checks {
      strict_required_status_checks_policy = true
      required_check {
        context = "validate"
      }
      required_check {
        context = "security"
      }
      required_check {
        context = "plan"
      }
    }

    # Require conversation resolution before merging
    required_linear_history = false
    required_signatures     = false

    # Require conversation resolution
    # Note: This is enforced at the repository level, not in rulesets
  }

  # Bypass actors - administrators can bypass in emergencies
  bypass_actors {
    actor_id    = 5 # Repository admins
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }
}

# ============================================================================
# Push Restrictions (using branch protection v4 for push restrictions)
# ============================================================================
# GitHub's modern ruleset API doesn't fully support push restrictions yet
# Using legacy branch protection for push restrictions to specific teams

resource "github_branch_protection_v3" "main_push_restrictions" {
  repository = github_repository.alz_workload_template.name
  branch     = "main"

  # Restrict who can push to matching branches
  restrictions {
    teams = [for team in data.github_team.push_allowance : team.slug]
    users = []
    apps  = []
  }

  # Note: Other protection rules are managed by the ruleset above
  # This resource only manages push restrictions
  enforce_admins = false
}

# ============================================================================
# Team Access
# ============================================================================
# Grant maintain access to platform-engineering team

resource "github_team_repository" "maintainers" {
  for_each   = data.github_team.maintainers
  team_id    = each.value.id
  repository = github_repository.alz_workload_template.name
  permission = "maintain"
}

# ============================================================================
# Repository Settings - Additional Configuration
# ============================================================================
# Note: Conversation resolution requirements are managed through branch protection
# rulesets and cannot be set directly via the repository resource in the current
# GitHub provider version. This must be configured manually through the GitHub UI
# or may be available in future provider versions.
