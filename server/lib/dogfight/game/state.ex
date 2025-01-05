defmodule Dogfight.Game.State do
  @moduledoc """
  Game state management, Ships and bullet logics, including collision.
  Represents the source of truth for each connecting player, and its updated
  based on the input of each one of the connected active players
  """

  # alias Dogfight.Game.Action
  alias Dogfight.Game.Spaceship
  alias Dogfight.Game.DefaultSpaceship
  alias Dogfight.Game.Vec2

  @type player_id :: String.t()

  @type power_up :: %{
          position: Vec2.t(),
          kind: :hp_plus_one | :hp_plus_three | :ammo_plus_one | nil
        }

  @type direction :: :idle | :up | :down | :left | :right

  @typep status :: :in_progress | :closed

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

  # @spec apply_action(t(), Game.Action.t(), non_neg_integer()) :: t()
  def apply_action(game_state, action, player_index) do
    case action do
      direction when direction in [:up, :down, :left, :right] ->
        move_ship(game_state, player_index, direction)

      :shoot ->
        shoot(game_state, player_index)

      _ ->
        game_state
    end
  end

  defp move_ship(game_state, player_index, direction) do
    player_position = Enum.at(game_state.spaceships, player_index).position

    player_position = move_ship_position(player_position, direction)

    ships =
      Enum.with_index(game_state.spaceships, fn
        player, ^player_index ->
          %{
            player
            | direction: direction,
              position: player_position
          }

        other, _i ->
          other
      end)

    %{
      game_state
      | spaceships: ships
    }
  end

  defp move_ship_position(%{x: x, y: y}, direction) do
    case direction do
      :up ->
        %{x: x, y: y - 3}

      :down ->
        %{x: x, y: y + 3}

      :left ->
        %{x: x - 3, y: y}

      :right ->
        %{x: x + 3, y: y}
    end
  end

  defp shoot(game_state, player_index) do
    %{
      game_state
      | spaceships:
          Enum.with_index(game_state.spaceships, fn
            player, ^player_index ->
              bullets = update_bullets(player.bullets, player)

              %{player | bullets: bullets}

            other, _i ->
              other
          end)
    }
  end

  defp update_bullets(bullets, player) do
    Enum.map_reduce(bullets, false, fn
      bullet, false when bullet.active == false ->
        {%{
           bullet
           | active: true,
             direction: player.direction,
             position: %{x: player.position.x, y: player.position.y}
         }, true}

      bullet, updated ->
        {bullet, updated}
    end)
    |> elem(0)
  end

  def idle, do: :idle
  def move_up, do: :up
  def move_down, do: :down
  def move_left, do: :left
  def move_right, do: :right
  def shoot, do: :shoot

  # @doc "Encode a `Game.State` struct into a raw binary payload"
  # @spec encode(t()) :: binary()
  # def encode(game_state) do
  #   binary_ships =
  #     game_state.spaceships
  #     |> Enum.map(&encode_ship/1)
  #     |> IO.iodata_to_binary()
  #
  #   power_up_kind = encode_power_up(game_state.power_up.kind)
  #
  #   total_length = byte_size(binary_ships) + 4 * 5 + 1
  #
  #   %{position: %{x: power_up_x, y: power_up_y}} = game_state.power_up
  #
  #   Encoding.encode_list([
  #     {total_length, :double_word},
  #     {game_state.player_index, :double_word},
  #     {power_up_x, :double_word},
  #     {power_up_y, :double_word},
  #     {power_up_kind, :half_word},
  #     {binary_ships, :binary}
  #   ])
  # end
  #
  # defp encode_ship(ship) do
  #   direction = Action.encode_direction(ship.direction)
  #
  #   binary_bullets =
  #     ship.bullets
  #     |> Enum.map(&encode_bullet/1)
  #     |> IO.iodata_to_binary()
  #
  #   %{x: x, y: y} = ship.position
  #
  #   Encoding.encode_list([
  #     {x, :double_word},
  #     {y, :double_word},
  #     {ship.hp, :double_word},
  #     {if(ship.alive, do: 1, else: 0), :half_word},
  #     {direction, :half_word},
  #     {binary_bullets, :binary}
  #   ])
  # end
  #
  # defp encode_bullet(bullet) do
  #   direction = Action.encode_direction(bullet.direction)
  #
  #   %{x: x, y: y} = bullet.position
  #
  #   Encoding.encode_list([
  #     {x, :double_word},
  #     {y, :double_word},
  #     {if(bullet.active, do: 1, else: 0), :half_word},
  #     {direction, :half_word}
  #   ])
  # end
  #
  # @doc "Decode a raw binary payload into a `Game.State` struct"
  # @spec decode!(binary()) :: t()
  # def decode!(binary) do
  #   <<_total_length::big-unsigned-integer-size(32), player_index::big-unsigned-integer-size(32),
  #     power_up_x::big-unsigned-integer-size(32), power_up_y::big-unsigned-integer-size(32),
  #     power_up_kind::big-unsigned-integer-size(8), players_blob::binary>> = binary
  #
  #   players =
  #     players_blob
  #     |> chunk_bits(@ship_byte_size)
  #     |> Enum.map(&decode_ship!/1)
  #
  #   %__MODULE__{
  #     spaceships: players,
  #     player_index: player_index,
  #     power_up: %{
  #       position: %{x: power_up_x, y: power_up_y},
  #       kind: decode_power_up(power_up_kind)
  #     }
  #   }
  # end
  #
  # defp decode_ship!(
  #        <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
  #          hp::big-unsigned-integer-size(32), alive::big-unsigned-integer-size(8),
  #          direction::big-unsigned-integer-size(8), bullets::binary>>
  #      ) do
  #   %{
  #     position: %{x: x, y: y},
  #     hp: hp,
  #     direction: Action.decode_direction(direction),
  #     alive: alive == 1,
  #     bullets:
  #       bullets
  #       |> chunk_bits(@bullet_byte_size)
  #       |> Enum.map(&decode_bullet!/1)
  #   }
  # end
  #
  # defp decode_bullet!(
  #        <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
  #          active::big-unsigned-integer-size(8), direction::big-unsigned-integer-size(8)>>
  #      ) do
  #   %{
  #     position: %{x: x, y: y},
  #     active: if(active == 0, do: false, else: true),
  #     direction: Action.decode_direction(direction)
  #   }
  # end
  #
  # defp chunk_bits(binary, n) do
  #   for <<chunk::binary-size(n) <- binary>>, do: <<chunk::binary-size(n)>>
  # end
  #
  # defp encode_power_up(nil), do: 0
  # defp encode_power_up(:hp_plus_one), do: 1
  # defp encode_power_up(:hp_plus_three), do: 2
  # defp encode_power_up(:ammo_plus_one), do: 3
  #
  # defp decode_power_up(0), do: nil
  # defp decode_power_up(1), do: :hp_plus_one
  # defp decode_power_up(2), do: :hp_plus_three
  # defp decode_power_up(3), do: :ammo_plus_one
end
