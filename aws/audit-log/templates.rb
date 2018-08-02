if ! config_present?('config/atmos.yml', 'recipes.default', "audit-log")
  add_config 'config/atmos.yml', 'recipes.default', ["audit-log"]
end
if ! config_present?('config/atmos.yml', 'environments.ops.recipes.^default',
                     ['audit-log'])
  add_config 'config/atmos.yml', 'environments.ops.recipes.^default',
             ['audit-log']
end
