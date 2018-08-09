if ! config_present?('config/atmos.yml', 'recipes.default', "user-data-support")
  add_config 'config/atmos.yml', 'recipes.default', ["user-data-support"]
end
