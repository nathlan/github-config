# GitHub Provider Configuration
# Authentication via GitHub App (recommended) or Personal Access Token

provider "github" {
  owner = var.github_owner

  # GitHub App Authentication (recommended for organizations)
  # Requires environment variables:
  # - GITHUB_APP_ID
  # - GITHUB_APP_INSTALLATION_ID
  # - GITHUB_APP_PEM_FILE
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_pem_file
  }

  # Alternative: Personal Access Token Authentication
  # Uncomment and comment out app_auth block above if using PAT
  # Requires environment variable: GITHUB_TOKEN
  # token = var.github_token
}
