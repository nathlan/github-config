output "repository_id" {
  description = "The ID of the created repository"
  value       = github_repository.repo.repo_id
}

output "repository_name" {
  description = "The name of the created repository"
  value       = github_repository.repo.name
}

output "repository_full_name" {
  description = "The full name of the repository (org/repo)"
  value       = github_repository.repo.full_name
}

output "repository_html_url" {
  description = "The URL to the repository on GitHub"
  value       = github_repository.repo.html_url
}

output "repository_ssh_clone_url" {
  description = "The SSH clone URL for the repository"
  value       = github_repository.repo.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "The HTTPS clone URL for the repository"
  value       = github_repository.repo.http_clone_url
}

output "default_branch" {
  description = "The default branch of the repository (typically 'main')"
  value       = "main"
}

output "copilot_firewall_allowlist" {
  description = "The domains added to the Copilot agent firewall allowlist"
  value       = var.copilot_firewall_allowlist
}

output "branch_protection_ruleset_id" {
  description = "The ID of the branch protection ruleset"
  value       = github_repository_ruleset.main_branch_protection.ruleset_id
}

output "organization" {
  description = "The GitHub organization"
  value       = data.github_organization.org.name
}
