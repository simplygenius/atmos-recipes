ask('Input the eks cluster name: ', varname: :name) { |q| q.validate = /\A\w+\Z/ }

template('aws/container/eks/eks_template.tf', "recipes/eks-#{name}.tf", context: binding)

# TODO: eks auto tags vpc/subnets - may conflict with the vpc/subnets created
# from atmos base recipes as they wont have those tags.  Could add a dedicated
# vpc to eks recipe or modify existing vpc to pass in tags
