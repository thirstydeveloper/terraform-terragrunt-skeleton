# The random provider needs no credentials, so these runs perform a real
# (in-memory) apply.

run "defaults" {
  command = apply

  assert {
    condition     = output.pet != ""
    error_message = "random_pet should produce a non-empty id"
  }

  assert {
    condition = alltrue([
      output.global_var == "unset",
      output.tier_var == "unset",
      output.env_var == "unset",
      output.layer_var == "unset",
      output.stack_var == "unset",
    ])
    error_message = "All *_var outputs should default to \"unset\""
  }
}

run "passes_through_vars" {
  command = apply

  variables {
    global_var = "g"
    tier_var   = "t"
    env_var    = "e"
    layer_var  = "l"
    stack_var  = "s"
  }

  assert {
    condition     = output.global_var == "g"
    error_message = "global_var not passed through"
  }

  assert {
    condition     = output.tier_var == "t"
    error_message = "tier_var not passed through"
  }

  assert {
    condition     = output.env_var == "e"
    error_message = "env_var not passed through"
  }

  assert {
    condition     = output.layer_var == "l"
    error_message = "layer_var not passed through"
  }

  assert {
    condition     = output.stack_var == "s"
    error_message = "stack_var not passed through"
  }
}
