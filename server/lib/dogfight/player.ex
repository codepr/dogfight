defmodule Dogfight.Player do
  @moduledoc """
  This module represents a player in the Dogfight game. It handles the player's
  connection, actions, and communication with the game server.
  """

  require Logger
  use GenServer

  alias Dogfight.Game.Codecs.BinaryCodec

  def start_link(player_id, socket) do
    GenServer.start_link(__MODULE__, {player_id, socket})
  end

  def init({player_id, socket}) do
    Logger.info("Player connected, registering to game server")
    {:ok, %{player_id: player_id, socket: socket}}
  end

  def handle_info({:tcp, _socket, data}, state) do
    with {:ok, event} <- BinaryCodec.decode_event(data) do
      Dogfight.Game.EventHandler.apply_event(self(), event)
    else
      {:ok, :codec_error} -> Logger.error("Decode failed, unknown event")
    end

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
    :gen_tcp.send(socket, BinaryCodec.encode(game_state))
  end
end
