# Data source to reference the existing repository
# This is used to import existing repository configuration
data "github_repository" "alz_workload_template" {
  full_name = "${var.github_organization}/${var.repository_name}"
}

# Data sources to reference existing teams by name
data "github_team" "maintainers" {
  for_each = toset(var.team_maintainers)
  slug     = each.value
}

data "github_team" "push_allowance" {
  for_each = toset(var.push_allowance_teams)
  slug     = each.value
}
