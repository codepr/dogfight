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
  def add_player(game_state, player_id, x \\ nil, y \\ nil) do
    case Map.get(game_state.players, player_id) do
      nil ->
        players =
          Map.put(
            game_state.players,
            player_id,
            DefaultSpaceship.spawn(@screen_width, @screen_height, x, y)
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
          game_state.players
          |> Map.new(fn {player_id, spaceship} ->
            {player_id, DefaultSpaceship.update_bullets(spaceship)}
          end)
          |> check_collisions()
    }
  end

  @spec check_collisions(%{player_id() => Spaceship.t()}) :: %{player_id() => Spaceship.t()}
  def check_collisions(players) do
    Enum.reduce(players, players, fn {player_id, spaceship}, acc ->
      Enum.reduce(spaceship.bullets, acc, fn bullet, acc_players ->
        if bullet.active? do
          Enum.reduce(acc_players, acc_players, fn {other_id, other_spaceship}, updated_players ->
            if player_id != other_id and intersects?(bullet, other_spaceship) do
              updated_bullet = %{bullet | active?: false}
              updated_other_spaceship = handle_bullet_hit(other_spaceship)

              Map.update!(updated_players, player_id, fn spaceship ->
                update_bullet_in_spaceship(spaceship, updated_bullet)
              end)
              |> Map.put(other_id, updated_other_spaceship)
            else
              updated_players
            end
          end)
        else
          acc_players
        end
      end)
    end)
  end

  defp intersects?(bullet, spaceship) do
    # Calculate the line segment of the bullet's movement
    bullet_start = bullet.previous_position
    bullet_end = bullet.position

    # Check for intersection between the bullet's path and the spaceship's radius
    distance_to_path =
      distance_to_segment(
        spaceship.position,
        bullet_start,
        bullet_end
      )

    distance_to_path <= spaceship.radius
  end

  # Helper function to calculate the shortest distance from a point to a line segment
  defp distance_to_segment(point, seg_start, seg_end) do
    segment_vector = %{x: seg_end.x - seg_start.x, y: seg_end.y - seg_start.y}
    point_vector = %{x: point.x - seg_start.x, y: point.y - seg_start.y}

    segment_length_sq = segment_vector.x * segment_vector.x + segment_vector.y * segment_vector.y

    # Projection factor t along the segment
    t =
      if segment_length_sq == 0 do
        0
      else
        (point_vector.x * segment_vector.x + point_vector.y * segment_vector.y) /
          segment_length_sq
      end

    # Clamp t to [0, 1] to ensure it's on the segment
    t = max(0, min(1, t))

    # Closest point on the segment to the given point
    closest_point = %{
      x: seg_start.x + t * segment_vector.x,
      y: seg_start.y + t * segment_vector.y
    }

    # Euclidean distance from the point to the closest point on the segment
    :math.sqrt(
      :math.pow(point.x - closest_point.x, 2) +
        :math.pow(point.y - closest_point.y, 2)
    )
  end

  defp handle_bullet_hit(spaceship) do
    # Handle what happens when a spaceship is hit by a bullet.
    # Example: Reduce health or mark it as destroyed.
    %{spaceship | hp: max(spaceship.hp - 1, 0)}
  end

  defp update_bullet_in_spaceship(spaceship, updated_bullet) do
    updated_bullets =
      Enum.map(spaceship.bullets, fn b ->
        if b.id == updated_bullet.id, do: updated_bullet, else: b
      end)

    %{spaceship | bullets: updated_bullets}
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
