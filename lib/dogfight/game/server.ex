defmodule Dogfight.Game.Server do
  require Logger
  use GenServer

  alias Dogfight.Game.State, as: GameState

  @tick_rate 50

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    game_state = GameState.new()
    schedule_tick()
    # TODO placeholder, put GameState here
    {:ok, %{players: [], game_state: game_state}}
  end

  def register_player(pid) do
    GenServer.call(__MODULE__, {:register_player, pid})
    GenServer.cast(__MODULE__, :spawn_new_ship)
  end

  def apply_action(pid, action, player_index) do
    GenServer.cast(__MODULE__, {:apply_action, pid, action, player_index})
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  @impl true
  def handle_info(:tick, state) do
    new_game_state = GameState.update(state.game_state)
    updated_state = %{state | game_state: new_game_state}
    broadcast_game_state(updated_state)
    schedule_tick()
    {:noreply, updated_state}
  end

  @impl true
  def handle_call({:register_player, pid}, from, state) do
    new_state =
      Map.update!(state, :players, fn players -> [{:player_id, %{pid: pid}} | players] end)

    {:reply, from, new_state}
  end

  @impl true
  def handle_cast(:spawn_new_ship, state) do
    game_state =
      case GameState.spawn_ship(state.game_state, 0) do
        {:ok, game_state} ->
          broadcast_game_state(%{state | game_state: game_state})
          game_state

        {:error, error} ->
          Logger.error("Failed spawining ship, reason: #{inspect(error)}")
          state.game_state
      end

    {:noreply, %{state | game_state: game_state}}
  end

  def handle_cast({:apply_action, _pid, action, player_index}, state) do
    game_state = GameState.apply_action(state.game_state, action, player_index)
    updated_state = %{state | game_state: game_state}
    broadcast_game_state(updated_state)
    {:noreply, updated_state}
  end

  defp broadcast_game_state(state) do
    Enum.each(state.players, fn {_, player} ->
      send_update(player.pid, state.game_state)
    end)
  end

  defp send_update(pid, state) do
    # TODO: Encode and send game state to player process
    send(pid, {:update, state})
  end
end
