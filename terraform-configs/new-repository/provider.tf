provider "github" {
  owner = var.github_organization
  # Token should be provided via GITHUB_TOKEN environment variable
  # Ensure the token has the following permissions:
  # - repo (full control of private repositories)
  # - admin:org (for organization settings)
  # - workflow (for GitHub Actions configuration)
}
