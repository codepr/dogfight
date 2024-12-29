defmodule Dogfight.Game.State do
  @moduledoc """
  Game state management, Ships and bullet logics, including collision.
  Represents the source of truth for each connecting player, and its updated
  based on the input of each one of the connected active players
  """

  @type t :: %__MODULE__{
          players: [ship()],
          active_players: non_neg_integer(),
          player_index: non_neg_integer(),
          powerup: powerup()
        }

  @typep ship :: %{
           coord: vec2(),
           hp: integer(),
           direction: integer(),
           alive: boolean(),
           bullets: [bullet()]
         }

  @typep powerup :: %{
           coord: vec2(),
           kind: :hp_plus_one | :hp_plus_three | :ammo_plus_one | nil
         }

  @typep vec2 :: %{
           x: integer(),
           y: integer()
         }

  @typep bullet :: %{
           coord: vec2(),
           direction: integer(),
           active: boolean()
         }

  defstruct [:players, :active_players, :player_index, :powerup]

  @max_players 5
  @max_bullets 5

  def new do
    %__MODULE__{
      player_index: 0,
      active_players: 0,
      powerup: %{coord: %{x: 0, y: 0}, kind: nil},
      players: Stream.repeatedly(&new_ship/0) |> Enum.take(@max_players)
    }
  end

  defp new_ship do
    %{
      coord: %{
        x: 0,
        y: 0
      },
      hp: 0,
      direction: :idle,
      alive: false,
      bullets: Stream.repeatedly(&new_bullet/0) |> Enum.take(@max_bullets)
    }
  end

  defp new_bullet do
    %{
      active: false,
      coord: %{
        x: 0,
        y: 0
      },
      direction: :idle
    }
  end

  @doc "Serialize a `Game.State` struct into a raw binary payload"
  @spec serialize(t()) :: binary()
  def serialize(game_state) do
    binary_ships =
      Enum.map(game_state.players, &serialize_ship/1) |> IO.iodata_to_binary()

    powerup_kind = encode_powerup(game_state.powerup.kind)

    total_length = byte_size(binary_ships) + 4 * 5 + 1

    %{coord: %{x: powerup_x, y: powerup_y}} = game_state.powerup

    <<integer_to_bin(total_length, 32)::binary,
      integer_to_bin(game_state.player_index, 32)::binary,
      integer_to_bin(game_state.active_players, 32)::binary,
      integer_to_bin(powerup_x, 32)::binary, integer_to_bin(powerup_y, 32)::binary,
      integer_to_bin(powerup_kind, 8)::binary, binary_ships::binary>>
  end

  defp serialize_ship(ship) do
    direction = encode_direction(ship.direction)

    binary_bullets =
      Enum.map(ship.bullets, &serialize_bullet/1) |> IO.iodata_to_binary()

    %{x: x, y: y} = ship.coord

    <<integer_to_bin(x, 32)::binary, integer_to_bin(y, 32)::binary,
      integer_to_bin(ship.hp, 32)::binary, integer_to_bin(ship.alive, 8)::binary,
      integer_to_bin(direction, 8)::binary, binary_bullets::binary>>
  end

  defp serialize_bullet(bullet) do
    direction = encode_direction(bullet.direction)

    %{x: x, y: y} = bullet.coord

    <<integer_to_bin(x, 32)::binary, integer_to_bin(y, 32)::binary,
      integer_to_bin(bullet.active, 8)::binary, integer_to_bin(direction, 8)::binary>>
  end

  @doc "Deserialize a raw binary payload into a `Game.State` struct"
  @spec deserialize!(binary()) :: t()
  def deserialize!(binary) do
    <<_total_length::big-unsigned-integer-size(32), player_index::big-unsigned-integer-size(32),
      active_players::big-unsigned-integer-size(32), power_up_x::big-unsigned-integer-size(32),
      power_up_y::big-unsigned-integer-size(32), power_up_kind::big-unsigned-integer-size(8),
      players_blob::binary>> = binary

    players =
      players_blob
      |> chunk_bits(64)
      |> Enum.map(&deserialize_ship!/1)

    %__MODULE__{
      players: players,
      active_players: active_players,
      player_index: player_index,
      powerup: %{
        coord: %{x: power_up_x, y: power_up_y},
        kind: decode_powerup(power_up_kind)
      }
    }
  end

  defp deserialize_ship!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           hp::big-unsigned-integer-size(32), alive::big-unsigned-integer-size(8),
           direction::big-unsigned-integer-size(8), bullets::binary>>
       ) do
    %{
      coord: %{x: x, y: y},
      hp: hp,
      direction: decode_direction(direction),
      alive: alive == 1,
      bullets:
        bullets
        |> chunk_bits(10)
        |> Enum.map(&deserialize_bullet!/1)
    }
  end

  defp deserialize_bullet!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           active::big-unsigned-integer-size(8), direction::big-unsigned-integer-size(8)>>
       ) do
    %{
      coord: %{x: x, y: y},
      active: if(active == 0, do: false, else: true),
      direction: decode_direction(direction)
    }
  end

  defp chunk_bits(binary, n) do
    for <<chunk::binary-size(n) <- binary>>, do: <<chunk::binary-size(n)>>
  end

  defp encode_direction(:idle), do: 0
  defp encode_direction(:up), do: 1
  defp encode_direction(:down), do: 2
  defp encode_direction(:left), do: 3
  defp encode_direction(:right), do: 4

  defp decode_direction(0), do: :idle
  defp decode_direction(1), do: :up
  defp decode_direction(2), do: :down
  defp decode_direction(3), do: :left
  defp decode_direction(4), do: :right

  defp encode_powerup(nil), do: 0
  defp encode_powerup(:hp_plus_one), do: 1
  defp encode_powerup(:hp_plus_three), do: 2
  defp encode_powerup(:ammo_plus_one), do: 3

  defp decode_powerup(0), do: nil
  defp decode_powerup(1), do: :hp_plus_one
  defp decode_powerup(2), do: :hp_plus_three
  defp decode_powerup(3), do: :ammo_plus_one

  defp integer_to_bin(true, size), do: integer_to_bin(1, size)
  defp integer_to_bin(false, size), do: integer_to_bin(0, size)
  defp integer_to_bin(data, size) when is_integer(data), do: <<data::integer-size(size)>>
end
