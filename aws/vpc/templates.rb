if ! config_present?('config/atmos.yml', 'recipes', 'vpc')
  add_config 'config/atmos.yml', 'recipes', ['vpc']
end
