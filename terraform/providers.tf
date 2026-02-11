# ============================================================================
# GitHub Provider Configuration
# ============================================================================
# Configures the GitHub provider for managing repository, organization, and
# team resources. Supports multiple authentication methods.

provider "github" {
  owner = var.github_organization

  # Authentication Methods (choose one):
  #
  # 1. Personal Access Token (PAT):
  #    Set GITHUB_TOKEN environment variable
  #    Required scopes: repo, admin:org, admin:repo_hook
  #
  # 2. GitHub App Authentication:
  #    Uncomment the app_auth block below and set environment variables:
  #    - GITHUB_APP_ID: The GitHub App ID
  #    - GITHUB_APP_INSTALLATION_ID: The installation ID
  #    - GITHUB_APP_PEM_FILE: The PEM file content
  #
  #    app_auth {}
  #
  # Note: The provider automatically reads from GITHUB_TOKEN or GITHUB_APP_*
  # environment variables, so no explicit credentials need to be set here.
}
