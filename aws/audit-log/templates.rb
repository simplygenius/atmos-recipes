if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "audit-log")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["audit-log"]
end
if ! config_present?('config/atmos/recipes.yml', 'environments.ops.recipes.^default',
                     ['audit-log'])
  add_config 'config/atmos/recipes.yml', 'environments.ops.recipes.^default',
             ['audit-log']
end
