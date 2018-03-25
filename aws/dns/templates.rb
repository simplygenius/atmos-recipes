if ! config_present?('config/atmos.yml', 'recipes', 'dns')
  add_config 'config/atmos.yml', 'recipes', ['dns']
end

if ! config_present?('config/atmos/dns.yml', 'domain')
  val = ask "Input the primary domain name for your organization:"
  add_config 'config/atmos/dns.yml', 'domain', val
end

# TODO: add domain registration using Aws::Route53Domains::Client
# val = ask "Register the domain with AWS Route53Domains?"
# https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Route53Domains/Client.html#register_domain-instance_method

say <<~EOF
  
  Make sure to set the name servers for your domain in your registrar after
  running an apply for these resources
EOF
