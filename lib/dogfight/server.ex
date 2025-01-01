defmodule Dogfight.Server do
  @moduledoc """
  Main entry point of the server, accepts connecting clients and defer their ownership
  to the game server. Each connected client is handled by a `GenServer`, the `Dogfight.Player`.
  The `Dogfight.Game.Server` governs the main logic of an instantiated game and broadcasts updates
  to each registered player.
  """
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
         player_id <- Dogfight.IndexAgent.next_id(),
         player_spec <- player_spec(client_socket, player_id),
         {:ok, pid} <- Horde.DynamicSupervisor.start_child(ClusterServiceSupervisor, player_spec) do
      Logger.info("Player #{player_id} connected")
      Dogfight.Game.Server.register_player(pid)
      :gen_tcp.controlling_process(client_socket, pid)
    else
      error -> Logger.error("Failed to accept connection, reason: #{inspect(error)}")
    end

    accept_loop(socket)
  end

  defp player_spec(socket, player_id) do
    %{
      id: Dogfight.Player,
      start: {Dogfight.Player, :start_link, [player_id, socket]},
      type: :worker,
      restart: :transient
    }
  end
end
