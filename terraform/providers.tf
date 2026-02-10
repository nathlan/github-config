provider "github" {
  owner = var.github_organization
  # token is read from GITHUB_TOKEN environment variable
}
