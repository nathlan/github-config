output "template_repositories" {
  description = "Map of template-based repositories with their details"
  value = {
    for name, repo in github_repository.template_repos : name => {
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

output "non_template_repositories" {
  description = "Map of non-template repositories with their details"
  value = {
    for name, repo in github_repository.non_template_repos : name => {
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

output "all_repositories" {
  description = "Map of all managed repositories with their details"
  value = merge(
    {
      for name, repo in github_repository.template_repos : name => {
        id                   = repo.repo_id
        name                 = repo.name
        full_name            = repo.full_name
        html_url             = repo.html_url
        ssh_clone_url        = repo.ssh_clone_url
        http_clone_url       = repo.http_clone_url
        default_branch       = "main"
        type                 = "template-based"
        branch_protection_id = github_repository_ruleset.main_branch_protection[name].ruleset_id
      }
    },
    {
      for name, repo in github_repository.non_template_repos : name => {
        id                   = repo.repo_id
        name                 = repo.name
        full_name            = repo.full_name
        html_url             = repo.html_url
        ssh_clone_url        = repo.ssh_clone_url
        http_clone_url       = repo.http_clone_url
        default_branch       = "main"
        type                 = "non-template"
        branch_protection_id = github_repository_ruleset.main_branch_protection[name].ruleset_id
      }
    }
  )
}

output "copilot_firewall_allowlist" {
  description = "The domains added to the Copilot agent firewall allowlist (consistent across all repositories)"
  value       = var.copilot_firewall_allowlist
}

output "repository_count" {
  description = "Number of repositories managed"
  value = {
    template     = length(github_repository.template_repos)
    non_template = length(github_repository.non_template_repos)
    total        = length(github_repository.template_repos) + length(github_repository.non_template_repos)
  }
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
