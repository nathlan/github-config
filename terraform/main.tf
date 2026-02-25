# ============================================================================
# Template-based Repositories (using alz-workload-template)
# ============================================================================

resource "github_repository" "template_repos" {
  for_each = { for repo in var.template_repositories : repo.name => repo }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  # Create from template repository
  template {
    owner                = var.github_owner
    repository           = "alz-workload-template"
    include_all_branches = false
  }

  # Enable features
  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = true

  # Merge settings
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Squash merge settings
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Security settings
  vulnerability_alerts = true

  # Topics for better discoverability
  topics = ["terraform-managed", "infrastructure-as-code"]
}

# ============================================================================
# Non-template Repositories (auto_init with README only)
# ============================================================================

resource "github_repository" "non_template_repos" {
  for_each = { for repo in var.non_template_repositories : repo.name => repo }

  name        = each.value.name
  description = each.value.description
  visibility  = each.value.visibility

  # Initialize with README (no template)
  auto_init = true

  # Enable features
  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = true

  # Merge settings
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Squash merge settings
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"

  # Security settings
  vulnerability_alerts = true

  # Topics for better discoverability
  topics = ["terraform-managed", "shared-resources"]
}

# ============================================================================
# Common Settings for All Repositories
# ============================================================================

locals {
  # Merge all repositories for common settings
  all_repos = merge(
    github_repository.template_repos,
    github_repository.non_template_repos
  )

  # Merge repository configurations for branch protection
  all_repo_configs = merge(
    { for repo in var.template_repositories : repo.name => repo },
    { for repo in var.non_template_repositories : repo.name => repo }
  )

  # Flatten collaborators for all repositories (template + non-template)
  all_collaborators = merge(
    {
      for pair in flatten([
        for repo in var.template_repositories : [
          for collab in repo.collaborators : {
            key        = "${repo.name}/${collab.username}"
            repo       = repo.name
            username   = collab.username
            permission = collab.permission
          }
        ]
      ]) : pair.key => pair
    },
    {
      for pair in flatten([
        for repo in var.non_template_repositories : [
          for collab in repo.collaborators : {
            key        = "${repo.name}/${collab.username}"
            repo       = repo.name
            username   = collab.username
            permission = collab.permission
          }
        ]
      ]) : pair.key => pair
    }
  )

  # Flatten team access for all repositories (template + non-template)
  all_team_access = merge(
    {
      for pair in flatten([
        for repo in var.template_repositories : [
          for team in repo.teams : {
            key        = "${repo.name}/${team.team_slug}"
            repo       = repo.name
            team_slug  = team.team_slug
            permission = team.permission
          }
        ]
      ]) : pair.key => pair
    },
    {
      for pair in flatten([
        for repo in var.non_template_repositories : [
          for team in repo.teams : {
            key        = "${repo.name}/${team.team_slug}"
            repo       = repo.name
            team_slug  = team.team_slug
            permission = team.permission
          }
        ]
      ]) : pair.key => pair
    }
  )
}

# ============================================================================
# Repository Access Management
# ============================================================================

# Grant direct user collaborator access to repositories
resource "github_repository_collaborator" "collaborators" {
  for_each = local.all_collaborators

  repository = each.value.repo
  username   = each.value.username
  permission = each.value.permission

  # Ensure repository exists before creating collaborator
  depends_on = [
    github_repository.template_repos,
    github_repository.non_template_repos
  ]
}

# Grant team access to repositories
resource "github_team_repository" "team_access" {
  for_each = local.all_team_access

  repository = each.value.repo
  team_id    = each.value.team_slug
  permission = each.value.permission

  # Ensure repository exists before creating team access
  depends_on = [
    github_repository.template_repos,
    github_repository.non_template_repos
  ]
}

# ============================================================================
# GitHub Actions Configuration
# ============================================================================

# Configure GitHub Actions permissions for all repositories
resource "github_actions_repository_permissions" "all_repos" {
  for_each = local.all_repos

  repository = each.value.name

  # Enable GitHub Actions
  enabled = true

  # Allow all actions to run
  allowed_actions = "all"
}

# Create repository variable for Copilot agent firewall allowlist (consistent across all repos)
# NOTE: Requires GitHub App with "Actions: Read and write" permission
# If you get "403 Resource not accessible by integration" error, set manage_copilot_firewall_variable = false
resource "github_actions_variable" "copilot_firewall_allowlist" {
  for_each = var.manage_copilot_firewall_variable ? local.all_repos : {}

  repository    = each.value.name
  variable_name = "COPILOT_AGENT_FIREWALL_ALLOW_LIST_ADDITIONS"
  value         = join(",", var.copilot_firewall_allowlist)
}

# Configure workflow permissions to allow GitHub Actions to create PRs
resource "github_workflow_repository_permissions" "all_repos" {
  for_each = local.all_repos

  repository = each.value.name

  # Set default workflow permissions for GITHUB_TOKEN
  # "read" = read-only access (more secure, recommended)
  # "write" = read-write access
  default_workflow_permissions = "read"

  # Allow GitHub Actions to create and approve pull requests
  can_approve_pull_request_reviews = var.enable_copilot_pr_from_actions
}

# Configure OIDC subject claims for all repositories to support reusable workflow federation.
# This enables tokens to include the called workflow reference via job_workflow_ref.
resource "github_actions_repository_oidc_subject_claim_customization_template" "all_repos" {
  for_each = local.all_repos

  repository  = each.value.name
  use_default = false

  include_claim_keys = [
    "repo",
    "context",
    "job_workflow_ref"
  ]
}

# Apply the same OIDC subject claim customization to the template repository.
resource "github_actions_repository_oidc_subject_claim_customization_template" "alz_workload_template" {
  repository  = github_repository.alz_workload_template.name
  use_default = false

  include_claim_keys = [
    "repo",
    "context",
    "job_workflow_ref"
  ]
}

# Create branch protection ruleset for main branch on all repositories
resource "github_repository_ruleset" "main_branch_protection" {
  for_each = local.all_repo_configs

  name        = "Protect main branch"
  repository  = local.all_repos[each.key].name
  target      = "branch"
  enforcement = "active"

  # Apply to main branch
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Bypass actors - allow GitHub Actions bot to bypass for PR creation
  bypass_actors {
    actor_id    = 5 # Repository admin role
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }

  # Allow source-repo-sync app to bypass for PR creation
  # This app syncs files from source repositories and auto-merges PRs
  dynamic "bypass_actors" {
    for_each = var.source_repo_sync_app_id != null ? [1] : []
    content {
      actor_id    = var.source_repo_sync_app_id
      actor_type  = "Integration"
      bypass_mode = "exempt"
    }
  }

  rules {
    # Prevent deletion of the main branch
    deletion = true

    # Prevent force pushes
    non_fast_forward = true

    # Require pull requests before merging
    pull_request {
      required_approving_review_count   = each.value.branch_protection_required_approving_review_count
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }

    # Require linear history (no merge commits from branches)
    required_linear_history = false

    # Optional: Enable Copilot code review for PRs
    # Uncomment if you want automatic Copilot code reviews
    # copilot_code_review {
    #   review_on_push            = true
    #   review_draft_pull_requests = false
    # }
  }
}

# ============================================================================
# ALZ Workload Template Repository Configuration
# ============================================================================
# This section manages the alz-workload-template repository, ensuring it is
# properly configured as a GitHub template repository for creating new
# workload repositories in the ALZ vending system.
#
# CRITICAL: This repository ALREADY EXISTS and is imported via imports.tf

resource "github_repository" "alz_workload_template" {
  name        = "alz-workload-template"
  description = "Template repository for ALZ workload repositories with pre-configured Terraform workflows"
  visibility  = "public"

  # CRITICAL: Mark as template repository
  # This enables the "Use this template" button and allows the ALZ vending
  # system to create new repositories from this template via Terraform
  is_template = true

  # Repository features
  has_issues   = true
  has_projects = false
  has_wiki     = false

  # Merge settings - aligned with ALZ standards
  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = true
  allow_auto_merge       = true
  delete_branch_on_merge = true

  # Security settings
  vulnerability_alerts = true

  # Topics for discoverability
  topics = [
    "azure",
    "terraform",
    "template",
    "landing-zone",
    "alz"
  ]

  lifecycle {
    # Prevent accidental deletion of the template repository
    prevent_destroy = true
  }
}

# Branch protection ruleset for alz-workload-template
resource "github_repository_ruleset" "alz_workload_template_main_protection" {
  name        = "Protect main branch"
  repository  = github_repository.alz_workload_template.name
  target      = "branch"
  enforcement = "active"

  # Apply to main branch
  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  # Bypass actors - allow repository admins to bypass for critical updates
  bypass_actors {
    actor_id    = 5 # Repository admin role
    actor_type  = "RepositoryRole"
    bypass_mode = "pull_request"
  }

  # Allow source-repo-sync app to bypass for PR creation
  # This app syncs files from source repositories and creates PRs
  dynamic "bypass_actors" {
    for_each = var.source_repo_sync_app_id != null ? [1] : []
    content {
      actor_id    = var.source_repo_sync_app_id
      actor_type  = "Integration"
      bypass_mode = "exempt"
    }
  }

  rules {
    # Prevent deletion of the main branch
    deletion = true

    # Prevent force pushes
    non_fast_forward = true

    # Require pull requests before merging
    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }

    # Require linear history (no merge commits from branches)
    required_linear_history = false
  }
}
