ask('Input the instance group name: ', varname: :name) { |q| q.validate = /\A\w+\Z/ }

agree('Would you like to auto scale the instance group? ', varname: :auto_scale) {|q| q.default = 'y' }

choose(varname: :load_balancer) do |menu|
  menu.prompt = "Add a load balancer in front of the instance group?  "
  menu.choices(:none, :internal, :external)
  menu.default = :none
end

if load_balancer != :none
  choose(varname: :lb_type) do |menu|
    menu.prompt = "Which type of load balancer should be used? "
    menu.choices(:network, :application)
    menu.default = :network
  end
  if lb_type == :network
    ask('Input the load balancer listener port: ', Integer, varname: :port) { |q| q.in = 0..65535 }
  end
end

template('aws/instance-group/instance_group_template.tf', "recipes/instance-group-#{name}.tf", context: binding)

if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "instance-group-variables")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["instance-group-variables"]
end

if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "instance-group-support")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["instance-group-support"]
end

if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "instance-group-permissions")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["instance-group-permissions"]
end

if ! config_present?('config/atmos/recipes.yml', 'environments.ops.recipes.^default', "instance-group-permissions")
  add_config 'config/atmos/recipes.yml', 'environments.ops.recipes.^default', ["instance-group-permissions"]
end

if ! config_present?('config/atmos/recipes.yml', 'recipes.default', "instance-group-#{name}")
  add_config 'config/atmos/recipes.yml', 'recipes.default', ["instance-group-#{name}"]
end
