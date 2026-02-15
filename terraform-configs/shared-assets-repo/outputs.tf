# Output values for the shared-assets repository

output "repository_name" {
  description = "Name of the created repository"
  value       = github_repository.shared_assets.name
}

output "repository_full_name" {
  description = "Full name of the repository (owner/name)"
  value       = github_repository.shared_assets.full_name
}

output "repository_url" {
  description = "URL of the repository"
  value       = github_repository.shared_assets.html_url
}

output "repository_ssh_clone_url" {
  description = "SSH clone URL for the repository"
  value       = github_repository.shared_assets.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "HTTP clone URL for the repository"
  value       = github_repository.shared_assets.http_clone_url
}

output "repository_id" {
  description = "GitHub repository ID"
  value       = github_repository.shared_assets.repo_id
}

output "repository_node_id" {
  description = "GraphQL global node ID of the repository"
  value       = github_repository.shared_assets.node_id
}
