defmodule Dogfight.Game.State do
  @moduledoc """
  Game state management, Ships and bullet logics, including collision.
  Represents the source of truth for each connecting player, and its updated
  based on the input of each one of the connected active players
  """

  alias Dogfight.Encoding.Helpers, as: Encoding
  alias Dogfight.Game.Action

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
  @base_hp 5
  @screen_width 800
  @screen_height 600
  @bullet_byte_size 10
  @ship_byte_size 64

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

  # TODO move to a map instead of the array, keepeing as-is for the first
  # translation pass
  @spec spawn_ship(t(), integer()) :: {:ok, t()} | {:error, :dismissed_ship}
  def spawn_ship(game_state, index) do
    if Enum.at(game_state.players, index).alive do
      {:ok, game_state}
    else
      # TODO fix this monstrosity
      new_state = %{
        game_state
        | active_players: game_state.active_players + 1,
          players:
            Enum.with_index(game_state.players, fn
              player, ^index ->
                %{
                  player
                  | alive: true,
                    hp: @base_hp,
                    coord: %{x: :rand.uniform(@screen_width), y: :rand.uniform(@screen_height)},
                    direction: :up
                }

              other, _i ->
                other
            end)
      }

      {:ok, new_state}
    end
  end

  @spec update(t()) :: t()
  def update(game_state) do
    %{game_state | players: update_ships(game_state.players)}
  end

  defp update_ships(players) do
    Enum.map(players, &update_ship/1)
  end

  defp update_ship(%{alive: false} = ship), do: ship

  defp update_ship(%{alive: true} = ship) do
    bullets = Enum.map(ship.bullets, &update_bullet/1)

    %{
      ship
      | bullets: bullets
    }
  end

  defp update_bullet(%{active: false} = bullet), do: bullet

  defp update_bullet(%{active: true} = bullet) do
    case bullet.direction do
      :up ->
        %{
          bullet
          | coord: %{x: bullet.coord.x, y: bullet.coord.y - 6}
        }

      :down ->
        %{
          bullet
          | coord: %{x: bullet.coord.x, y: bullet.coord.y + 6}
        }

      :left ->
        %{
          bullet
          | coord: %{x: bullet.coord.x - 6, y: bullet.coord.y}
        }

      :right ->
        %{
          bullet
          | coord: %{x: bullet.coord.x + 6, y: bullet.coord.y}
        }

      _ ->
        bullet
    end
  end

  @spec apply_action(t(), Game.Action.t(), non_neg_integer()) :: t()
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
    player_coord = Enum.at(game_state.players, player_index).coord

    player_coord = move_ship_coord(player_coord, direction)

    ships =
      Enum.with_index(game_state.players, fn
        player, ^player_index ->
          %{
            player
            | direction: direction,
              coord: player_coord
          }

        other, _i ->
          other
      end)

    %{
      game_state
      | players: ships
    }
  end

  defp move_ship_coord(%{x: x, y: y}, direction) do
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
      | players:
          Enum.with_index(game_state.players, fn
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
             coord: %{x: player.coord.x, y: player.coord.y}
         }, true}

      bullet, updated ->
        {bullet, updated}
    end)
    |> elem(0)
  end

  @doc "Encode a `Game.State` struct into a raw binary payload"
  @spec encode(t()) :: binary()
  def encode(game_state) do
    binary_ships =
      game_state.players
      |> Enum.map(&encode_ship/1)
      |> IO.iodata_to_binary()

    powerup_kind = encode_powerup(game_state.powerup.kind)

    total_length = byte_size(binary_ships) + 4 * 5 + 1

    %{coord: %{x: powerup_x, y: powerup_y}} = game_state.powerup

    Encoding.encode_list([
      {total_length, :double_word},
      {game_state.player_index, :double_word},
      {game_state.active_players, :double_word},
      {powerup_x, :double_word},
      {powerup_y, :double_word},
      {powerup_kind, :half_word},
      {binary_ships, :binary}
    ])
  end

  defp encode_ship(ship) do
    direction = Action.encode_direction(ship.direction)

    binary_bullets =
      ship.bullets
      |> Enum.map(&encode_bullet/1)
      |> IO.iodata_to_binary()

    %{x: x, y: y} = ship.coord

    Encoding.encode_list([
      {x, :double_word},
      {y, :double_word},
      {ship.hp, :double_word},
      {if(ship.alive, do: 1, else: 0), :half_word},
      {direction, :half_word},
      {binary_bullets, :binary}
    ])
  end

  defp encode_bullet(bullet) do
    direction = Action.encode_direction(bullet.direction)

    %{x: x, y: y} = bullet.coord

    Encoding.encode_list([
      {x, :double_word},
      {y, :double_word},
      {if(bullet.active, do: 1, else: 0), :half_word},
      {direction, :half_word}
    ])
  end

  @doc "Decode a raw binary payload into a `Game.State` struct"
  @spec decode!(binary()) :: t()
  def decode!(binary) do
    <<_total_length::big-unsigned-integer-size(32), player_index::big-unsigned-integer-size(32),
      active_players::big-unsigned-integer-size(32), power_up_x::big-unsigned-integer-size(32),
      power_up_y::big-unsigned-integer-size(32), power_up_kind::big-unsigned-integer-size(8),
      players_blob::binary>> = binary

    players =
      players_blob
      |> chunk_bits(@ship_byte_size)
      |> Enum.map(&decode_ship!/1)

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

  defp decode_ship!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           hp::big-unsigned-integer-size(32), alive::big-unsigned-integer-size(8),
           direction::big-unsigned-integer-size(8), bullets::binary>>
       ) do
    %{
      coord: %{x: x, y: y},
      hp: hp,
      direction: Action.decode_direction(direction),
      alive: alive == 1,
      bullets:
        bullets
        |> chunk_bits(@bullet_byte_size)
        |> Enum.map(&decode_bullet!/1)
    }
  end

  defp decode_bullet!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           active::big-unsigned-integer-size(8), direction::big-unsigned-integer-size(8)>>
       ) do
    %{
      coord: %{x: x, y: y},
      active: if(active == 0, do: false, else: true),
      direction: Action.decode_direction(direction)
    }
  end

  defp chunk_bits(binary, n) do
    for <<chunk::binary-size(n) <- binary>>, do: <<chunk::binary-size(n)>>
  end

  defp encode_powerup(nil), do: 0
  defp encode_powerup(:hp_plus_one), do: 1
  defp encode_powerup(:hp_plus_three), do: 2
  defp encode_powerup(:ammo_plus_one), do: 3

  defp decode_powerup(0), do: nil
  defp decode_powerup(1), do: :hp_plus_one
  defp decode_powerup(2), do: :hp_plus_three
  defp decode_powerup(3), do: :ammo_plus_one
end
