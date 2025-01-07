defmodule Dogfight.Game.State do
  @moduledoc """
  Game state management, Ships and bullet logics, including collision.
  Represents the source of truth for each connecting player, and its updated
  based on the input of each one of the connected active players
  """

  alias Dogfight.Game.Event
  alias Dogfight.Game.Spaceship
  alias Dogfight.Game.DefaultSpaceship
  alias Dogfight.Game.Vec2

  @type player_id :: String.t()

  @type power_up_kind :: :hp_plus_one | :hp_plus_three | :ammo_plus_one | nil

  @type power_up :: %{
          position: Vec2.t(),
          kind: power_up_kind()
        }

  @type direction :: :idle | :up | :down | :left | :right

  @typep status :: :in_progress | :closed | nil

  @type t :: %__MODULE__{
          players: %{player_id() => Spaceship.t()},
          power_ups: [power_up()],
          status: status()
        }

  defstruct [:players, :power_ups, :status]

  @screen_width 800
  @screen_height 600

  def new do
    %__MODULE__{
      power_ups: [],
      status: :closed,
      players: %{}
    }
  end

  @spec add_player(t(), player_id()) :: {:ok, t()} | {:error, :dismissed_ship}
  def add_player(game_state, player_id) do
    case Map.get(game_state.players, player_id) do
      nil ->
        players =
          Map.put(
            game_state.players,
            player_id,
            DefaultSpaceship.spawn(@screen_width, @screen_height)
          )

        {:ok, %{game_state | players: players}}

      %{alive?: true} ->
        {:ok, game_state}

      _spaceship ->
        {:error, :dismissed_ship}
    end
  end

  @spec drop_player(t(), player_id()) :: t()
  def drop_player(game_state, player_id) do
    Map.update!(game_state, :players, fn players ->
      Map.delete(players, player_id)
    end)
  end

  @spec update(t()) :: t()
  def update(game_state) do
    %{
      game_state
      | players:
          Map.new(game_state.players, fn {player_id, spaceship} ->
            {player_id, DefaultSpaceship.update_bullets(spaceship)}
          end)
    }
  end

  defp fetch_spaceship(players_map, player_id) do
    case Map.fetch(players_map, player_id) do
      :error -> {:error, :dismissed_ship}
      %{alive?: false} -> {:error, :dismissed_ship}
      {:ok, _spaceship} = ok -> ok
    end
  end

  @spec apply_event(t(), Event.t()) :: {:ok, t()} | {:error, :dismissed_ship}
  def apply_event(game_state, {:move, {player_id, direction}}) do
    with {:ok, spaceship} <- fetch_spaceship(game_state.players, player_id) do
      {:ok,
       %{
         game_state
         | players:
             Map.put(game_state.players, player_id, DefaultSpaceship.move(spaceship, direction))
       }}
    end
  end

  def apply_event(game_state, {:shoot, player_id}) do
    with {:ok, spaceship} <- fetch_spaceship(game_state.players, player_id) do
      {:ok,
       %{
         game_state
         | players: Map.put(game_state.players, player_id, DefaultSpaceship.shoot(spaceship))
       }}
    end
  end

  def apply_event(game_state, {:spawn_power_up, power_up_kind}) do
    power_up = %{position: Vec2.random(@screen_width, @screen_height), kind: power_up_kind}

    {:ok,
     %{
       game_state
       | power_ups: [power_up | game_state.power_ups]
     }}
  end

  def apply_event(_game_state, _event), do: raise("Not implemented")

  def idle, do: :idle
  def move_up, do: :up
  def move_down, do: :down
  def move_left, do: :left
  def move_right, do: :right
  def shoot, do: :shoot
end
