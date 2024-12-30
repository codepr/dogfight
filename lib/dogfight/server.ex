defmodule Dogfight.Server do
  require Logger

  alias Dogfight.ClusterServiceSupervisor

  def listen(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :raw` - receives data as it comes (stream of binary over the wire)
    # 3. `active: true` - non blocking on `:gen_tcp.recv/2`, doesn't wait for data to be available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: true, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    accept_loop(socket)
  end

  defp accept_loop(socket) do
    with {:ok, client_socket} <- :gen_tcp.accept(socket),
         player_spec <- worker_spec(client_socket),
         {:ok, pid} <- Horde.DynamicSupervisor.start_child(ClusterServiceSupervisor, player_spec) do
      Dogfight.Game.Server.register_player(pid)
      :gen_tcp.controlling_process(client_socket, pid)
    else
      error -> IO.inspect(error)
    end

    accept_loop(socket)
  end

  defp worker_spec(socket) do
    %{
      id: Dogfight.Player,
      start: {Dogfight.Player, :start_link, [:player_id, socket]},
      type: :worker,
      restart: :transient
    }
  end
end
