if ! config_present?("config/atmos.yml", 'recipes', 'atmos-scaffold')
  insert_into_file "config/atmos.yml", "  - atmos-scaffold\n", :after => /^recipes:\n/
end

if ! config_present?("config/atmos.yml", 'org')
  insert_into_file "config/atmos.yml", :after => /^org:$/ do
    val = ask "Input a short name that represents your organization:"
    " #{val}"
  end
end

if ! config_present?("config/atmos.yml", 'environments.ops.account_id')
  insert_into_file "config/atmos.yml", :after => /^environments:\n\s+ops:\n\s+account_id:$/ do
    val = ask "Input the AWS account id for the ops environment:"
    " #{val}"
  end
end
