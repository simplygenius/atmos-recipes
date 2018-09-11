if ! config_present?('config/atmos/recipes.yml', 'recipes.default', 'dns')
  add_config 'config/atmos/recipes.yml', 'recipes.default', ['dns']
end

if ! config_present?('config/atmos/dns.yml', 'domain')
  ask "Input the primary domain name for your organization: ", varname: :domain
  add_config 'config/atmos/dns.yml', 'domain', "\#{atmos_env}.#{domain}"
end

# TODO: add domain registration using Aws::Route53Domains::Client
# agree("Register the domain with AWS Route53Domains? ", varname: :perform_domain_registration) {|q| q.default = 'y' }
# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Route53Domains/Client.html#register_domain-instance_method

say <<~EOF
  
  Make sure to set the name servers for your domain in your registrar after
  running an apply for these resources
EOF
