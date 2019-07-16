#!/usr/bin/env ruby

require 'clamp'
require 'marloss'
require 'aws-sdk-ec2'

Clamp do

  banner "Queries all instances with a matching group tag, and sets the Name tag to <name>-<index>.domain"

  option ["-i", "--instance_id"], "INSTANCE_ID", "the instance id", required: true
  option ["-n", "--name"], "NAME", "the name to base the hostname on", required: true
  option ["-d", "--domain"], "DOMAIN", "the domain for the hostname", required: true
  option ["-t", "--group_tag"], "GROUP_TAG", "the name of the tag used to group like instances", required: true
  option ["-v", "--group_tag_value"], "GROUP_TAG_VALUE", "the value of the tag used to group like instances", required: true
  option ["-l", "--lock_table_name"], "LOCK_TABLE_NAME", "the dynamodb table to use for locks", required: true
  option ["-k", "--lock_key"], "LOCK_KEY", "the key in the dynamodb table to use for locks", default: "AtmosReserveHostnameLock"
  option ["-x", "--index_digits"], "INDEX_DIGITS", "the number of digits to format the index as in the hostname", default: 2
  option ["-o", "--output"], "OUTPUT", "write the new name to the given file"

  def execute
    # First check if the Name tag is already on this instance and abort if this is
    # the case
    #
    ec2 = Aws::EC2::Resource.new
    instance = ec2.instance(instance_id)
    tags = Hash[instance.tags.collect {|t| [t[:key], t[:value]]}]
    name_tag = tags['Name']
    new_name = nil

    if name_tag
      $stderr.puts "Name tag already exists for this instance: #{name_tag} - using for hostname"
      new_name = name_tag
    else

      # Distributed race condition here if we spin up multiple instances
      # simultaneously, so use a lock
      #
      with_lock do

        # Extract the Name tag for all the instances in the same group, and sed out the
        # digits and sort
        #
        instances = ec2.instances({
            filters: [
                {
                    name: "instance-state-name",
                    values: ["pending", "running"]
                },
                {
                    name: "tag:#{group_tag}",
                    values: ["#{group_tag_value}*"]
                    # wildcard to handle appended launchconfig id when recreating instances on update in
                    # instance-group-dynamic
                }
            ]
        })
        existing_numbers = []
        instances.collect do |inst|
          tags = Hash[inst.tags.collect {|t| [t[:key], t[:value]]}]
          instance_name = tags['Name']
          next if instance_name.nil?

          instance_name = instance_name.sub(/\..*/, '')
          if instance_name =~ /-(\d+)\./
            idx = $1
            existing_numbers << idx.to_i
          else
            $stderr.puts "Count not find an index in Name tag '#{tags['Name']}' for instance #{inst.id}"
          end
        end

        # Walk the existing numbers to see if we need to fill in an empty spot or go
        # after all of them
        #
        current = 1
        existing_numbers.sort.each do |num|
          if current != num
            new_name = current.to_s
            break
          end
          current += 1
        end
        new_name = current.to_s if new_name.nil?

        new_name = sprintf("#{group_tag_value}-%0#{index_digits}d.#{domain}", new_name)
        $stderr.puts "Setting Name tag to '#{new_name}'"
        instance.create_tags(tags: [{key: 'Name', value: new_name}])

      end

      if output
        $stderr.puts "Writing reserved name '#{new_name}' to '#{output}'"
        File.write(output, new_name)
      else
        $stdout.puts new_name
      end

    end
  end

  def with_lock
    @store ||= Marloss::Store.new(lock_table_name, lock_key)
    @locker ||= Marloss::Locker.new(@store, "my_resource")

    begin
      # block until we get a lock
      @locker.wait_until_lock_obtained

      # do stuff
      yield
    ensure
      # delete the lock
      @locker.release_lock
    end

  end

end
