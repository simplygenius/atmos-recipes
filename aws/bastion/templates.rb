global_rule = <<~EOF
    resource "aws_security_group_rule" "global-bastion-ingress" {
      security_group_id = "${module.vpc.global_security_group_id}"
    
      type = "ingress"
      from_port = 22
      to_port = 22
      protocol = "tcp"
    
      source_security_group_id = "${module.instance-group-bastion.security_group_id}"
    }
EOF

append_to_file "recipes/instance-group-bastion.tf", global_rule

agree('Would you like to add a bastion proxy config to ~/.ssh/config? ', varname: :ssh_config) {|q| q.default = 'n' }

if ssh_config
  ask('Input your ssh user name: ', varname: :username)
  ask('Input your domain: ', varname: :domain)

  ssh_config = <<~EOF
    Host bastion.#{domain}
      User #{username}
    
    Host *.#{domain} !bastion.#{domain}
      ProxyCommand ssh bastion.#{domain} -W %h:%p
      User #{username}
  EOF

  append_to_file File.expand_path("~/.ssh/config"), ssh_config
end
