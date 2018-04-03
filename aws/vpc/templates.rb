if ! config_present?('config/atmos.yml', 'recipes.default', 'vpc')
  add_config 'config/atmos.yml', 'recipes.default', ['vpc']
end
