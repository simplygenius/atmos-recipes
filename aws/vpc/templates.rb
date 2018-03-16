if ! config_present?("config/atmos.yml", 'recipes', 'vpc')
  insert_into_file "config/atmos.yml", "  - vpc\n", :after => /^recipes:\n/
end

marker_comment = "\n# Variables for the aws/vpc template\n#\n"
insert_into_file "config/atmos.yml",
                 marker_comment,
                 :after => /^local_name_prefix:.*\n/

if ! config_present?("config/atmos.yml", 'domain')
  insert_into_file "config/atmos.yml", :after => /^#{marker_comment}/ do
    val = ask "Input the primary domain name for your organization:"
    "domain: #{val}\n"
  end
end

if ! config_present?("config/atmos.yml", 'ops_email')
  insert_into_file "config/atmos.yml", :after => /^domain:.*\n/ do
    val = ask "Input the email address for receiving ops related emails:"
    "ops_email: #{val}\n"
  end
end

if ! config_present?("config/atmos.yml", 'az_count')
  insert_into_file "config/atmos.yml", "az_count: 2\n", :after => /^ops_email:.*\n/
end

if ! config_present?("config/atmos.yml", 'vpc_cidr')
  insert_into_file "config/atmos.yml", "vpc_cidr: 10.10.0.0/16\n", :after => /^az_count:.*\n/
end
