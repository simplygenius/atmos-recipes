#!/usr/bin/env bash

# fail fast
set -e

assume_role.rb -a ${ops_account} -r ${iam_inspect_role} \
  lookup_iam_users.rb ${lookup_iam_users_args} \
  | update_iam_users.rb
