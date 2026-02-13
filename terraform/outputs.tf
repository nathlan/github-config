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

# ALZ Workload Template Repository Outputs
output "alz_workload_template_name" {
  description = "Name of the ALZ workload template repository"
  value       = github_repository.alz_workload_template.name
}

output "alz_workload_template_url" {
  description = "URL of the ALZ workload template repository"
  value       = github_repository.alz_workload_template.html_url
}

output "alz_workload_template_is_template" {
  description = "Whether the repository is marked as a template"
  value       = github_repository.alz_workload_template.is_template
}

# ALZ Workload Repository Outputs
output "alz_prod_api_repo" {
  description = "Details of the alz-prod-api-repo workload repository"
  value = {
    id                   = github_repository.alz_prod_api_repo.repo_id
    name                 = github_repository.alz_prod_api_repo.name
    full_name            = github_repository.alz_prod_api_repo.full_name
    html_url             = github_repository.alz_prod_api_repo.html_url
    ssh_clone_url        = github_repository.alz_prod_api_repo.ssh_clone_url
    http_clone_url       = github_repository.alz_prod_api_repo.http_clone_url
    default_branch       = "main"
    branch_protection_id = github_repository_ruleset.alz_prod_api_repo_main_protection.ruleset_id
    team_access          = "platform-engineering: admin"
  }
}
