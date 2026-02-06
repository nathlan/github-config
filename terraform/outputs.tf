output "repositories" {
  description = "Map of created repositories with their details"
  value = {
    for name, repo in github_repository.repos : name => {
      id                   = repo.repo_id
      name                 = repo.name
      full_name            = repo.full_name
      html_url             = repo.html_url
      ssh_clone_url        = repo.ssh_clone_url
      http_clone_url       = repo.http_clone_url
      default_branch       = "main"
      branch_protection_id = github_repository_ruleset.main_branch_protection[name].ruleset_id
    }
  }
}

output "copilot_firewall_allowlist" {
  description = "The domains added to the Copilot agent firewall allowlist (consistent across all repositories)"
  value       = var.copilot_firewall_allowlist
}

output "organization" {
  description = "The GitHub organization"
  value       = var.github_organization
}

output "repository_count" {
  description = "Number of repositories created"
  value       = length(github_repository.repos)
}
