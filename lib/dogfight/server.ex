defmodule Dogfight.Server do
  require Logger

  alias GameState

  def accept(port) do
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
         {:ok, pid} <- GenServer.start_link(Player, {:player_id, client_socket}) do
      # TODO add supervisor
      # DynamicSupervisor.start_child(
      #   MyApp.ClientSupervisor,
      #   {Player, socket}
      # ) do
      :gen_tcp.controlling_process(client_socket, pid)
    end

    accept_loop(socket)
  end
end
