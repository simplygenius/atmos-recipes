if ! config_present?('config/atmos.yml', 'recipes', 'service-cluster')
  add_config 'config/atmos.yml', 'recipes', ['service-cluster']
end

name = ask('Input the service name (empty to skip):')
if name.present?
  rds = ask('Does the service need a RDS database?', limited_to: ['y', 'n']) =~ /^y/i
  lb = ask('Does the service need a load balancer?', limited_to: ['y', 'n']) =~ /^y/i
  if lb
    external = ask('Should the Load Balancer be internet facing?', limited_to: ['y', 'n']) =~ /^y/i
  end

  template('aws/service/service_template.tf', "recipes/service-#{name}.tf", context: binding)

  if ! config_present?('config/atmos.yml', 'recipes', "service-#{name}")
    add_config 'config/atmos.yml', 'recipes', ["service-#{name}"]
  end

  if rds
    say <<~EOF
    
      Before applying, you should generate a database password and add it to
      secrets: atmos secret set #{name}_db_password <your_password>
    EOF
  end

end
