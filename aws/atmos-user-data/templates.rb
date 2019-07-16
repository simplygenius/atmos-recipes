if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "user-data-support")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["user-data-support"]
end
