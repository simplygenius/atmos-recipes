if ! config_present?('config/atmos.yml', 'recipes.default', 'static-website')
  add_config 'config/atmos.yml', 'recipes.default', ['static-website']
end
