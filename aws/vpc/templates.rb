if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'vpc')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['vpc']
end
