if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'service')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['service']
end

ask('Input the name of the cluster the service will belong to: ', varname: :cluster_name) { |q| q.validate = /\A\w+\Z/ }
agree('Is the cluster ec2 backed (vs fargate)? ', varname: :cluster_ec2_backed) { |q| q.default = 'n' }
generate('aws/container/ecs-cluster', ctx: {aws: {container: {ecs_cluster: {name: cluster_name, ec2_backed: cluster_ec2_backed}}}})

ask('Input the service name (empty to skip): ', varname: :name) { |q| q.validate = /\A\w+\Z/ }
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
