name = ask('Input the instance group name (empty to skip): ')

if name.present?
  # dynamic = ask('Should this instance group be auto scale capable? ') {|q| q.default = 'y' }
  auto_scale = agree('Would you like to auto scale the instance group? ') {|q| q.default = 'y' }

  template('aws/instance-group/instance_group_template.tf', "recipes/instance-group-#{name}.tf", context: binding)

  if ! config_present?('config/atmos.yml', 'recipes.default', "instance-group-#{name}")
    add_config 'config/atmos.yml', 'recipes.default', ["instance-group-#{name}"]
  end

end
