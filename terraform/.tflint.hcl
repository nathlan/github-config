# TFLint Configuration
# https://github.com/terraform-linters/tflint

config {
  # Enable module inspection
  module = true
  
  # Force the provider source to be set
  force = false
  
  # Disable color output
  disabled_by_default = false
}

# Enable the GitHub provider plugin
plugin "github" {
  enabled = true
  version = "0.3.0"
  source  = "github.com/terraform-linters/tflint-ruleset-github"
}

# Enable Terraform core rules
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Terraform Core Rules Configuration
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = false # We're using local backend for now
}

# GitHub-specific rules
rule "github_repository_description_required" {
  enabled = false # We have default values
}

rule "github_repository_homepage_url_required" {
  enabled = false # Optional field
}

rule "github_repository_topics_required" {
  enabled = true
}

rule "github_repository_vulnerability_alerts_enabled" {
  enabled = true
}
