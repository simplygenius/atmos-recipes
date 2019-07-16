#!/usr/bin/env ruby

require 'clamp'
require 'open3'
require 'csv'
require 'etc'
require 'fileutils'

Clamp do

  include FileUtils

  banner "Produces a csv of the user in the given iam group(s), including the ssh public key"
  option ["-f", "--file"], "FILE", "the csv file to read the users from"

  def execute

    unix_group = "atmos-iam"
    sudo_group = "atmos-sudo"
    # group named ssh is needed for some linux flavors
    ssh_group = "ssh"

    sh "groupadd -f #{unix_group}"
    sh "groupadd -f #{ssh_group}"
    sh "groupadd -f #{sudo_group}"

    # Allow passwdless sudo for members of the group
    File.write("/etc/sudoers.d/95-atmos-iam-users", "%#{sudo_group} ALL=(ALL) NOPASSWD:ALL")

    seen_users = []
    csvin = file ? open(file, "r") : $stdin

    # For each IAM user, create the system user if need be, then add SSH keys from
    # IAM into that user's authorized_keys
    CSV(csvin) do |csv_in|
      csv_in.each do |csv_row|
        sysuser = csv_row[0]
        iamuser = csv_row[1]
        allow_ssh = (csv_row[2] == 'true')
        allow_sudo = (csv_row[3] == 'true')
        public_keys = csv_row[4..-1]

        $stderr.puts "Ensuring system user '#{sysuser}' for IAM user '#{iamuser}'"

        system_user_exists = Etc.getpwnam(sysuser) rescue nil
        if ! system_user_exists
          $stderr.puts "Adding new system user: #{sysuser}"
          useradd_groups = "#{unix_group}"
          useradd_groups << ",#{ssh_group}" if allow_ssh
          useradd_groups << ",#{sudo_group}" if allow_sudo
          sh "useradd -m -s /bin/bash -G #{useradd_groups} -c '#{iamuser}' #{sysuser}"
        end

        if allow_ssh
          $stderr.puts "Setting up ssh keys"

          home_dir = Etc.getpwnam(sysuser).dir
          mkdir_p("#{home_dir}/.ssh")
          chmod(0700, "#{home_dir}/.ssh")
          rm_f("#{home_dir}/.ssh/authorized_keys")
          touch("#{home_dir}/.ssh/authorized_keys")
          chown_R(sysuser, sysuser, "#{home_dir}/.ssh")

          authkeys = public_keys.collect { |k| "#{k} #{iamuser}"}.join("\n")
          File.write("#{home_dir}/.ssh/authorized_keys", authkeys)

          seen_users << sysuser
        end

      end

    end

    # Remove local users that are no longer in IAM
    local_users = Etc.getgrnam(unix_group).mem
    users_to_remove = local_users - seen_users
    users_to_remove.each do |user|
      $stderr.puts "User no longer in IAM, removing: $user"
      sh "userdel --force --remove #{user}"
    end

  end

  def sh(cmd)
    system(cmd) || fail("Shell command failed: #{cmd}")
  end
end
