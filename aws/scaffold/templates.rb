if ! config_present?('config/atmos.yml', 'recipes.bootstrap',
                     ['atmos-variables', 'atmos-bootstrap'])
  add_config 'config/atmos.yml', 'recipes.bootstrap',
             ['atmos-variables', 'atmos-bootstrap']
end

if ! config_present?('config/atmos.yml', 'recipes.default',
                     ['atmos-variables', 'atmos-permissions', 'atmos-support'])
  add_config 'config/atmos.yml', 'recipes.default',
             ['atmos-variables', 'atmos-permissions', 'atmos-support']
end

if ! config_present?('config/atmos.yml', 'environments.ops.recipes.^default',
                     ['atmos-variables', 'atmos-permissions', 'atmos-support'])
  add_config 'config/atmos.yml', 'environments.ops.recipes.^default',
             ['atmos-variables', 'atmos-permissions', 'atmos-support']
end

if ! config_present?('config/atmos.yml', 'org')
  val = ask 'Input a short name that represents your organization: '
  add_config 'config/atmos.yml', 'org', val
end

if ! config_present?('config/atmos.yml', 'environments.ops.account_id')
  val = ask 'Input the AWS account id for the ops environment: '
  add_config 'config/atmos.yml', 'environments.ops.account_id', val
end
