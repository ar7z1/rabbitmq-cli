## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2016 Pivotal Software, Inc.  All rights reserved.


defmodule RabbitMQ.CLI.Ctl.Commands.SetTopicPermissionsCommand do
  @behaviour RabbitMQ.CLI.CommandBehaviour
  use RabbitMQ.CLI.DefaultOutput
  @flags [:vhost]

  def merge_defaults(args, opts) do
    {args, Map.merge(%{vhost: "/"}, opts)}
  end

  def validate([], _) do
    {:validation_failure, :not_enough_args}
  end
  def validate([_|_] = args, _) when length(args) < 3 do
    {:validation_failure, :not_enough_args}
  end

  def validate([_|_] = args, _) when length(args) > 3 do
    {:validation_failure, :too_many_args}
  end
  def validate(_, _), do: :ok

  def run([user, exchange, pattern], %{node: node_name, vhost: vhost}) do
    :rabbit_misc.rpc_call(node_name,
      :rabbit_auth_backend_internal,
      :set_topic_permissions,
      [user, vhost, exchange, pattern]
    )
  end

  def usage, do: "set_topic_permissions [-p <vhost>] <user> <exchange> <pattern>"


  def banner([user, exchange, _], %{vhost: vhost}), do: "Setting topic permissions on \"#{exchange}\" for user \"#{user}\" in vhost \"#{vhost}\" ..."
end