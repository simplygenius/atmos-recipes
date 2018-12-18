if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'service')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['service']
end

ask('Input the cluster name: ', varname: :name) { |q| q.validate = /\A\w+\Z/ }

# TODO add (?) a check to only prompt if atmos pro since ec2 cluster templates are
# only present there
agree('Is the cluster ec2 backed (vs fargate)? ', varname: :ec2_backed) {|q| q.default = 'n' }
ecs_tmpl = ec2_backed ? 'aws/container/ecs-ec2' : 'aws/container/ecs'
generate(ecs_tmpl)

template('aws/container/ecs-cluster/cluster_template.tf', "recipes/cluster-#{name}.tf", context: binding)
if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "cluster-#{name}")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["cluster-#{name}"]
end
