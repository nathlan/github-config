provider "github" {
  owner = var.github_organization

  # GitHub App authentication (recommended for CI/CD and automation)
  # Set these environment variables:
  # - GITHUB_APP_ID: The GitHub App ID (numeric)
  # - GITHUB_APP_INSTALLATION_ID: The installation ID (numeric)  
  # - GITHUB_APP_PEM_FILE: Path to the private key PEM file
  #
  # Or for CI/CD with secret content:
  # - GH_APP_ID: The GitHub App ID
  # - GH_APP_INSTALLATION_ID: The installation ID
  # - GH_APP_PRIVATE_KEY: The PEM file content (multi-line string)

  app_auth {
    id              = var.app_id              # from GITHUB_APP_ID or GH_APP_ID
    installation_id = var.app_installation_id # from GITHUB_APP_INSTALLATION_ID or GH_APP_INSTALLATION_ID
    pem_file        = var.app_pem_file        # from GITHUB_APP_PEM_FILE or file path
  }
}
