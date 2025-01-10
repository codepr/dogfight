defmodule Dogfight.Game.EventHandler do
  @moduledoc """
  Represents a game server for the Dogfight game. It handles the game state and
  player actions. It is intended as the main source of thruth for each instantiated game,
  broadcasting the game state to each connected player every `@tick` milliseconds.
  """
  require Logger
  use GenServer

  alias Dogfight.Game.State, as: GameState

  @tick_rate_ms 50

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    game_state = GameState.new()
    schedule_tick()
    {:ok, %{players: %{}, game_state: game_state}}
  end

  def register_player(pid, player_id) do
    GenServer.call(__MODULE__, {:register_player, pid, player_id})
    GenServer.cast(__MODULE__, {:add_player, player_id})
  end

  def apply_event(pid, event) do
    case event do
      {:player_connection, player_id} ->
        GenServer.call(__MODULE__, {:register_player, pid, player_id})
        GenServer.cast(__MODULE__, {:add_player, player_id})

      {:player_disconnection, player_id} ->
        GenServer.call(__MODULE__, {:unregister_player, player_id})
        GenServer.cast(__MODULE__, {:drop_player, player_id})

      event ->
        GenServer.cast(__MODULE__, {:apply_event, pid, event})
    end
  end

  defp schedule_tick() do
    Process.send_after(self(), :tick, @tick_rate_ms)
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
  def handle_call({:register_player, pid, player_id}, from, state) do
    new_state =
      Map.update!(state, :players, fn players ->
        Map.put(players, player_id, pid)
      end)

    {:reply, from, new_state}
  end

  @impl true
  def handle_call({:unregister_player, player_id}, from, state) do
    new_state =
      Map.update!(state, :players, fn players ->
        Map.delete(players, player_id)
      end)

    {:reply, from, new_state}
  end

  @impl true
  def handle_cast({:add_player, player_id}, state) do
    game_state =
      case GameState.add_player(state.game_state, player_id) do
        {:ok, game_state} ->
          broadcast_game_state(%{state | game_state: game_state})
          game_state

        {:error, error} ->
          Logger.error("Failed spawining spaceship, reason: #{inspect(error)}")
          state.game_state
      end

    {:noreply, %{state | game_state: game_state}}
  end

  @impl true
  def handle_cast({:drop_player, player_id}, state) do
    {:noreply, %{state | game_state: GameState.drop_player(state.game_state, player_id)}}
  end

  @impl true
  def handle_cast({:apply_event, _pid, event}, state) do
    updated_state =
      with {:ok, game_state} <- GameState.apply_event(state.game_state, event) do
        updated_state = %{state | game_state: game_state}
        broadcast_game_state(updated_state)
        updated_state
      else
        e ->
          Logger.error("Failed to apply event, reason: #{inspect(e)}")
          state
      end

    {:noreply, updated_state}
  end

  defp broadcast_game_state(state) do
    Enum.each(Map.values(state.players), fn pid ->
      send(pid, {:update, state.game_state})
    end)
  end
end
