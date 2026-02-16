# Import blocks for existing GitHub resources
# https://developer.hashicorp.com/terraform/language/import

# Import the existing alz-workload-template repository
import {
  to = github_repository.alz_workload_template
  id = "alz-workload-template"
}

# Import the existing github-config repository
import {
  to = github_repository.non_template_repos["github-config"]
  id = "github-config"
}

# Import the existing shared-assets repository (if it exists)
# Uncomment after the repository is created:
# import {
#   to = github_repository.non_template_repos["shared-assets"]
#   id = "shared-assets"
# }

# Note: The branch protection rulesets are new and will be created, not imported.
# If they already exist, add import blocks with the format:
# import {
#   to = github_repository_ruleset.main_branch_protection["repo-name"]
#   id = "repo-name:<ruleset_id>"
# }
