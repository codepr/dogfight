defmodule Dogfight.Player do
  require Logger
  use GenServer

  alias Dogfight.Game.State, as: GameState

  def start_link(player_id, socket) do
    GenServer.start_link(__MODULE__, {player_id, socket})
  end

  def init({player_id, socket}) do
    Logger.info("Player connected, registering to game server")
    {:ok, %{player_id: player_id, socket: socket}}
  end

  def handle_info({:tcp, _socket, data}, state) do
    data |> GameState.decode!() |> IO.inspect()
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Player disconnected")
    {:noreply, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("Player transmission error #{inspect(reason)}")
    {:noreply, state}
  end

  def handle_info({:update, game_state}, state) do
    send_game_update(state.socket, game_state)
    {:noreply, state}
  end

  defp send_game_update(socket, game_state) do
    # TODO: Encode and send game state update to client
    :gen_tcp.send(socket, encode_game_state(game_state))
  end

  defp encode_game_state(game_state) do
    GameState.encode(game_state)
  end
end
