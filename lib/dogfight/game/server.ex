defmodule Dogfight.Game.Server do
  use GenServer

  @tick_rate 50

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    schedule_tick()
    # TODO placeholder, put GameState here
    {:ok, %{players: [], powerups: []}}
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  def handle_info(:tick, state) do
    new_state = update_game_state(state)
    broadcast_game_state(new_state)
    schedule_tick()
    {:noreply, new_state}
  end

  defp update_game_state(_state) do
    # TODO Update player positions, resolve collisions, etc.
  end

  defp broadcast_game_state(state) do
    Enum.each(state.players, fn {_, player} ->
      send_update(player.pid, state)
    end)
  end

  defp send_update(pid, state) do
    # TODO: Serialize and send game state to player process
    send(pid, {:update, state})
  end
end
