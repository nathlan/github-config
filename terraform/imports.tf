# Import blocks for existing GitHub resources
# https://developer.hashicorp.com/terraform/language/import

# Import the existing alz-workload-template repository
import {
  to = github_repository.alz_workload_template
  id = "alz-workload-template"
}

# Note: The branch protection ruleset for alz-workload-template is new
# and will be created, not imported. If it already exists, add an import
# block with the format:
# import {
#   to = github_repository_ruleset.alz_workload_template_main_protection
#   id = "alz-workload-template:<ruleset_id>"
# }
