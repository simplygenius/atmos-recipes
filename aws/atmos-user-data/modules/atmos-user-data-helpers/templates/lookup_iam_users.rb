#!/usr/bin/env ruby

require 'clamp'
require 'open3'
require 'csv'
require 'set'
require 'aws-sdk-iam'

Clamp do

  banner "Produces a csv of the user in the given iam group(s), including the ssh public key"

  option ["-g", "--group"], "GROUP", "the IAM group", required: true, multivalued: true
  option ["-s", "--ssh_group"], "SSH_GROUP", "the IAM group where membership grants ssh permissions", multivalued: true
  option ["-u", "--sudo_group"], "SUDO_GROUP", "the IAM group where membership grants sudo permissions", multivalued: true
  option ["-o", "--output"], "OUTPUT", "the file to output the users to"

  def execute

    client = Aws::IAM::Client.new

    csvout = output ? open(output, "wb") : $stdout
    CSV(csvout) do |csv|

      seen_users = Set.new
      group_list.each do  |group_name|
        group = Aws::IAM::Group.new(group_name)
        group.users.each do |user|
          next if seen_users.include?(user.name)

          allow_ssh = false
          allow_sudo = false
          if ssh_group_list.any? || sudo_group_list.any?
            other_groups = user.groups.collect(&:name)

            if ssh_group_list.any?
              allow_ssh = other_groups.any? {|o| ssh_group_list.include?(o) }
            end
            if sudo_group_list.any?
              allow_sudo = other_groups.any? {|o| sudo_group_list.include?(o) }
            end
          end

          public_keys = []
          key_ids = client.list_ssh_public_keys(user_name: user.name).ssh_public_keys.collect {|key| key.ssh_public_key_id}
          key_ids.each do |key_id|
            key = client.get_ssh_public_key(user_name: user.name, ssh_public_key_id: key_id, encoding: "SSH").ssh_public_key
            if key.status == 'Active'
              public_keys << key.ssh_public_key_body
            end
          end

          # Extract unix username from iam username - basically dropping the @.. if its an email
          sysuser = user.name.gsub(/@.*/, '')

          csv << [sysuser, user.name, allow_ssh, allow_sudo, *public_keys]
          seen_users << user.name
        end
      end

    end

  end

end
