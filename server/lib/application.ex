defmodule Dogfight.Application do
  @moduledoc """
  Documentation for `Dogfight`.
  Server component for the Dogfight battle arena game, developed to have
  some fun with game dev and soft-real time distributed systems.
  """

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("DOGFIGHT_TCP_PORT") || "6699")

    children = [
      {Cluster.Supervisor, [topologies(), [name: Dogfight.ClusterSupervisor]]},
      {
        Horde.Registry,
        name: Dogfight.ClusterRegistry, keys: :unique, members: :auto
      },
      {
        Horde.DynamicSupervisor,
        name: Dogfight.ClusterServiceSupervisor, strategy: :one_for_one, members: :auto
      },
      Dogfight.Game.EventHandler,
      # Dogfight.IndexAgent,
      Supervisor.child_spec({Task, fn -> Dogfight.Server.listen(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: Dogfight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Can also read this from conf files, but to keep it simple just hardcode it for now.
  # It is also possible to use different strategies for autodiscovery.
  # Following strategy works best for docker setup we using for this app.
  defp topologies do
    [
      game_state_nodes: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [:"app@n1.dev", :"app@n2.dev", :"app@n3.dev"]
        ]
      ]
    ]
  end
end
