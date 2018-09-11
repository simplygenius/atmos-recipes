if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'service')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['service']
end

ask('Input the service name (empty to skip): ', varname: :name)
if name.present?
  agree('Does the service need a RDS database? ', varname: :use_rds) {|q| q.default = 'y' }
  agree('Does the service need a load balancer? ', varname: :use_lb) {|q| q.default = 'y' }
  if use_lb
    agree('Should the Load Balancer be internet facing? ', varname: :external_lb) {|q| q.default = 'y' }
  end

  template('aws/service/service_template.tf', "recipes/service-#{name}.tf", context: binding)

  if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "service-#{name}")
    add_config 'config/atmos/recipes.yml', 'recipes.default', ["service-#{name}"]
  end

  if rds
    say <<~EOF
    
      Before applying, you should generate a database password and add it to
      secrets for each env:
      atmos -e <env> secret set service_#{name}_db_password <your_password>

    EOF
  end

end
