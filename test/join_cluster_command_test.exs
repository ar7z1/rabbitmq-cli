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
## The Initial Developer of the Original Code is Pivotal Software, Inc.
## Copyright (c) 2016-2017 Pivotal Software, Inc.  All rights reserved.


defmodule JoinClusterCommandTest do
  use ExUnit.Case, async: false
  import TestHelper

  @command RabbitMQ.CLI.Ctl.Commands.JoinClusterCommand

  setup_all do
    RabbitMQ.CLI.Core.Distribution.start()


    start_rabbitmq_app()

    on_exit([], fn ->
      start_rabbitmq_app()


    end)

    :ok
  end

  setup do
    {:ok, opts: %{
      node: get_rabbit_hostname(),
      disc: true,
      ram: false,
    }}
  end

  test "validate: specifying both --disc and --ram is reported as invalid", context do
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["a"], Map.merge(context[:opts], %{disc: true, ram: true}))
    )
  end
  test "validate: specifying no target node is reported as an error", context do
    assert @command.validate([], context[:opts]) ==
      {:validation_failure, :not_enough_args}
  end
  test "validate: specifying multiple target nodes is reported as an error", context do
    assert @command.validate(["a", "b", "c"], context[:opts]) ==
      {:validation_failure, :too_many_args}
  end

  # TODO
  #test "run: successful join as a disc node", context do
  #end

  # TODO
  #test "run: successful join as a RAM node", context do
  #end

  test "run: joining self is invalid", context do
    stop_rabbitmq_app()
    assert match?(
      {:error, :cannot_cluster_node_with_itself},
      @command.run([context[:opts][:node]], context[:opts]))
    start_rabbitmq_app()
  end

  # TODO
  test "run: request to an active node fails", context do
   assert match?(
     {:error, :mnesia_unexpectedly_running},
    @command.run([context[:opts][:node]], context[:opts]))
  end

  test "run: request to a non-existent node returns nodedown", context do
    target = :jake@thedog

    opts = %{
      node: target,
      disc: true,
      ram: false,
    }
    # We use "self" node as the target. It's enough to trigger the error.
    assert match?(
      {:badrpc, :nodedown},
      @command.run([context[:opts][:node]], opts))
  end

  test "run: joining a non-existent node returns nodedown", context do
    target = :jake@thedog

    stop_rabbitmq_app()
    assert match?(
      {:badrpc_multi, :nodedown, [_]},
      @command.run([target], context[:opts]))
    start_rabbitmq_app()
  end

  test "banner", context do
    assert @command.banner(["a"], context[:opts]) =~
      ~r/Clustering node #{get_rabbit_hostname()} with a/
  end

  test "output mnesia is running error", context do
    exit_code = RabbitMQ.CLI.Core.ExitCodes.exit_software
    assert match?({:error, ^exit_code,
                   "Mnesia is still running on node " <> _},
                   @command.output({:error, :mnesia_unexpectedly_running}, context[:opts]))

  end
end
