if ! config_present?("config/atmos.yml", 'recipes', 'dns')
  insert_into_file "config/atmos.yml", "  - dns\n", :after => /^recipes:\n/
end

if ! config_present?("config/atmos/dns.yml", 'domain')
  insert_into_file "config/atmos/dns.yml", :after => /^domain:/ do
    val = ask "Input the primary domain name for your organization:"
    " #{val}"
  end
end

say <<~EOF
  
  Make sure to set the name servers for your domain in your registrar after
  running an apply for these resources
EOF
