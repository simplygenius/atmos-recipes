if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'static-website')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['static-website']
end
