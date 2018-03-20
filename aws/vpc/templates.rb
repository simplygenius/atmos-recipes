if ! config_present?("config/atmos.yml", 'recipes', 'vpc')
  insert_into_file "config/atmos.yml", "  - vpc\n", :after => /^recipes:\n/
end
