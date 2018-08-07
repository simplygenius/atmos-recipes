#!/usr/bin/env ruby

require 'clamp'
require 'aws-sdk-route53'

Clamp do

  banner "Sets or deletes the hostname in route53"

  option ["-i", "--ip"], "IP", "the IP address to create a dns entry for", required: true
  option ["-n", "--name"], "NAME", "the dns name to assign to the ip", required: true
  option ["-z", "--zone"], "ZONE", "the zone id to create the record in", required: true
  option ["-a", "--action"], "ACTION", "the dns action to perform (upsert|delete)", required: true do |a|
    raise ArgumentError.new("action must be one of upsert or delete") unless %w(upsert delete).include?(a)
    a
  end
  option ["-t", "--ttl"], "TTL", "the TTL for the record", default: 300 do |a|
    Integer(a)
  end

  def execute

    $stderr.puts "#{action}ing dns record: #{name} => #{ip}"

    route53 = Aws::Route53::Client.new
    route53.change_resource_record_sets(
        change_batch: {
            changes: [
                {
                    action: action.upcase,
                    resource_record_set: {
                        name: name,
                        type: "A",
                        ttl: ttl,
                        resource_records: [
                            {
                                value: ip
                            }
                        ]
                    }
                }
            ],
            comment: "Set from instance by Atmos",
        },
        hosted_zone_id: zone
    )

  end

end

