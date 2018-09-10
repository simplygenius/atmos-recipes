if ! config_present?('config/atmos/recipes.yml', 'recipes.bootstrap',
                     ['atmos-variables', 'atmos-bootstrap'])
  add_config 'config/atmos/recipes.yml', 'recipes.bootstrap',
             ['atmos-variables', 'atmos-bootstrap']
end

if ! config_present?('config/atmos/recipes.yml', 'recipes.default',
                     ['atmos-variables', 'atmos-permissions', 'atmos-support'])
  add_config 'config/atmos/recipes.yml', 'recipes.default',
             ['atmos-variables', 'atmos-permissions', 'atmos-support']
end

if ! config_present?('config/atmos/recipes.yml', 'environments.ops.recipes.^default',
                     ['atmos-variables', 'atmos-permissions', 'atmos-support'])
  add_config 'config/atmos/recipes.yml', 'environments.ops.recipes.^default',
             ['atmos-variables', 'atmos-permissions', 'atmos-support']
end

if ! config_present?('config/atmos.yml', 'org')
  val = ask 'Input a short name that represents your organization: ', varname: :org
  add_config 'config/atmos.yml', 'org', val
end

if ! config_present?('config/atmos.yml', 'environments.ops.account_id')
  val = ask 'Input the AWS account id for the ops environment: ', varname: :account_id
  add_config 'config/atmos.yml', 'environments.ops.account_id', val
end
