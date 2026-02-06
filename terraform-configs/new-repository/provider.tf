provider "github" {
  owner = var.github_organization

  # GitHub App authentication using environment variables
  # When GITHUB_APP_XXX environment variables are set, the provider reads them automatically
  # No need to specify id, installation_id, or pem_file in the app_auth block
  #
  # Required environment variables (set in GitHub Actions workflow):
  # - GITHUB_APP_ID: The GitHub App ID (from GH_CONFIG_APP_ID)
  # - GITHUB_APP_INSTALLATION_ID: The installation ID (from GH_CONFIG_INSTALLATION_ID)
  # - GITHUB_APP_PEM_FILE: The PEM file content (from GH_CONFIG_PRIVATE_KEY)
  
  app_auth {} # When using `GITHUB_APP_XXX` environment variables
}
