defmodule Dogfight.Player do
  use GenServer

  alias Dogfight.Game.State, as: GameState

  def start_link(player_id, socket) do
    GenServer.start_link(__MODULE__, {player_id, socket}, name: via_tuple(player_id))
  end

  def init({player_id, socket}) do
    {:ok, %{player_id: player_id, socket: socket, position: {0, 0}, health: 100}}
  end

  def handle_info({:tcp, _socket, data}, state) do
    data |> GameState.deserialize!() |> IO.inspect()
    {:noreply, state}
  end

  def handle_info({:update, game_state}, state) do
    send_game_update(state.socket, game_state)
    {:noreply, state}
  end

  defp send_game_update(socket, game_state) do
    # TODO: Serialize and send game state update to client
    :gen_tcp.send(socket, encode_game_state(game_state))
  end

  defp encode_game_state(_game_state), do: nil

  defp via_tuple(player_id) do
    {:via, Registry, {TankRegistry, player_id}}
  end
end
