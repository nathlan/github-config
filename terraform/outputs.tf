output "repository_id" {
  description = "The ID of the repository"
  value       = github_repository.alz_workload_template.id
}

output "repository_full_name" {
  description = "The full name of the repository (organization/name)"
  value       = github_repository.alz_workload_template.full_name
}

output "repository_html_url" {
  description = "The HTML URL of the repository"
  value       = github_repository.alz_workload_template.html_url
}

output "repository_ssh_clone_url" {
  description = "The SSH clone URL of the repository"
  value       = github_repository.alz_workload_template.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "The HTTP clone URL of the repository"
  value       = github_repository.alz_workload_template.http_clone_url
}

output "is_template" {
  description = "Whether the repository is a template repository"
  value       = github_repository.alz_workload_template.is_template
}

output "branch_protection_ruleset_id" {
  description = "The ID of the main branch protection ruleset"
  value       = github_repository_ruleset.main_branch_protection.id
}

output "team_access" {
  description = "Teams with access to the repository"
  value = {
    for team_slug, team_repo in github_team_repository.maintainers :
    team_slug => {
      team_id    = team_repo.team_id
      permission = team_repo.permission
    }
  }
}
