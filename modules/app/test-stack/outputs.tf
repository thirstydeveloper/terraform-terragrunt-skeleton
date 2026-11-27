output "pet" {
  value = random_pet.pet.id
}

output "global_var" {
  value = var.global_var
}

output "tier_var" {
  value = var.tier_var
}

output "env_var" {
  value = var.env_var
}

output "layer_var" {
  value = var.layer_var
}

output "stack_var" {
  value = var.stack_var
}
