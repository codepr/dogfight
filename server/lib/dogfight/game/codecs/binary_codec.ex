defmodule Dogfight.Game.Codecs.BinaryCodec do
  @moduledoc """
  Binary implementation of the game econding and decoding logic
  """

  @behaviour Dogfight.Game.Codec

  alias Dogfight.Game.Codecs.Helpers
  alias Dogfight.Game.State
  alias Dogfight.Game.Vec2

  @power_up_byte_size Helpers.double_word_byte_size() * 2 + Helpers.half_word_byte_size()
  @bullet_byte_size Helpers.double_word_byte_size() * 2 + Helpers.half_word_byte_size() * 2
  @player_id_byte_size Helpers.quad_word_byte_size()
  @spaceship_byte_size @player_id_byte_size + 5 * @bullet_byte_size +
                         3 * Helpers.double_word_byte_size() + 2 * Helpers.half_word_byte_size()

  @impl true
  def encode_event(event) do
    Helpers.encode_list([
      {event_to_int(event), :half_word}
    ])
  end

  @impl true
  def decode_event(binary) do
    <<action::big-unsigned-integer-size(8)>> = binary

    {:ok, int_to_event(action)}
  rescue
    _e -> {:error, :codec_error}
  end

  defp event_to_int(action) do
    case action do
      :shoot -> 5
      direction -> encode_direction(direction)
    end
  end

  defp int_to_event(intval) do
    case intval do
      5 -> :shoot
      direction -> decode_direction(direction)
    end
  end

  @doc "Encode a `Game.State` struct into a raw binary payload"
  @impl true
  def encode(game_state) do
    binary_ships =
      game_state.players
      |> Enum.map(fn {player_id, spaceship} -> encode_spaceship(player_id, spaceship) end)
      |> IO.iodata_to_binary()

    binary_power_ups =
      game_state.power_ups |> Enum.map(&encode_power_up/1) |> IO.iodata_to_binary()

    binary_status = Atom.to_string(game_state.status)

    binary_status_byte_size = byte_size(binary_status)
    binary_ships_byte_size = byte_size(binary_ships)
    binary_power_ups_byte_size = byte_size(binary_power_ups)

    total_length =
      binary_ships_byte_size +
        binary_power_ups_byte_size +
        binary_status_byte_size +
        Helpers.double_word_byte_size() +
        Helpers.half_word_byte_size() +
        Helpers.word_byte_size()

    Helpers.encode_list([
      {total_length, :double_word},
      {binary_status_byte_size, :half_word},
      {binary_status, :binary},
      {binary_power_ups_byte_size, :word},
      {binary_power_ups, :binary},
      {binary_ships, :binary}
    ])
  end

  defp encode_spaceship(player_id, spaceship) do
    direction = encode_direction(spaceship.direction)

    binary_bullets =
      spaceship.bullets
      |> Enum.map(&encode_bullet/1)
      |> IO.iodata_to_binary()

    %{x: x, y: y} = spaceship.position

    Helpers.encode_list([
      {x, :double_word},
      {y, :double_word},
      {spaceship.hp, :double_word},
      {if(spaceship.alive?, do: 1, else: 0), :half_word},
      {direction, :half_word},
      {player_id, :binary},
      {binary_bullets, :binary}
    ])
  end

  defp encode_power_up(power_up) do
    kind = power_up_to_int(power_up.kind)
    %{position: %{x: x, y: y}} = power_up

    Helpers.encode_list([
      {x, :double_word},
      {y, :double_word},
      {kind, :half_word}
    ])
  end

  defp encode_bullet(bullet) do
    direction = encode_direction(bullet.direction)

    %{x: x, y: y} = bullet.position

    Helpers.encode_list([
      {x, :double_word},
      {y, :double_word},
      {if(bullet.active?, do: 1, else: 0), :half_word},
      {direction, :half_word}
    ])
  end

  @doc "Decode a raw binary payload into a `Game.State` struct"
  @impl true
  def decode(binary) do
    <<_total_length::big-unsigned-integer-size(32), status_len::big-unsigned-integer-size(8),
      rest::binary>> = binary

    <<status::binary-size(status_len), power_ups_len::big-unsigned-integer-size(16),
      rest::binary>> = rest

    <<power_ups_bin::binary-size(power_ups_len), player_records::binary>> = rest

    power_ups =
      power_ups_bin
      |> chunk_bits(@power_up_byte_size)
      |> Enum.map(&decode_power_up!/1)

    players =
      player_records
      |> chunk_bits(@spaceship_byte_size)
      |> Enum.map(&decode_spaceship!/1)
      |> Map.new()

    {:ok,
     %State{
       players: players,
       power_ups: power_ups,
       status: String.to_existing_atom(status)
     }}
  rescue
    # TODO add custom errors
    _e -> {:error, :codec_error}
  end

  defp decode_power_up!(
         <<power_up_x::big-unsigned-integer-size(32), power_up_y::big-unsigned-integer-size(32),
           power_up_kind::big-unsigned-integer-size(8)>>
       ) do
    %{position: %Vec2{x: power_up_x, y: power_up_y}, kind: int_to_power_up(power_up_kind)}
  end

  defp decode_spaceship!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           hp::big-unsigned-integer-size(32), alive::big-unsigned-integer-size(8),
           direction::big-unsigned-integer-size(8), player_id::binary-size(@player_id_byte_size),
           bullets::binary>>
       ) do
    {player_id,
     %{
       position: %Vec2{x: x, y: y},
       hp: hp,
       direction: decode_direction(direction),
       alive?: alive == 1,
       bullets:
         bullets
         |> chunk_bits(@bullet_byte_size)
         |> Enum.map(&decode_bullet!/1)
     }}
  end

  defp decode_bullet!(
         <<x::big-unsigned-integer-size(32), y::big-unsigned-integer-size(32),
           active::big-unsigned-integer-size(8), direction::big-unsigned-integer-size(8)>>
       ) do
    %{
      position: %{x: x, y: y},
      active?: if(active == 0, do: false, else: true),
      direction: decode_direction(direction)
    }
  end

  defp chunk_bits(binary, n) do
    for <<chunk::binary-size(n) <- binary>>, do: <<chunk::binary-size(n)>>
  end

  defp power_up_to_int(nil), do: 0
  defp power_up_to_int(:hp_plus_one), do: 1
  defp power_up_to_int(:hp_plus_three), do: 2
  defp power_up_to_int(:ammo_plus_one), do: 3

  defp int_to_power_up(0), do: nil
  defp int_to_power_up(1), do: :hp_plus_one
  defp int_to_power_up(2), do: :hp_plus_three
  defp int_to_power_up(3), do: :ammo_plus_one

  def encode_direction(:idle), do: 0
  def encode_direction(:up), do: 1
  def encode_direction(:down), do: 2
  def encode_direction(:left), do: 3
  def encode_direction(:right), do: 4

  def decode_direction(0), do: :idle
  def decode_direction(1), do: :up
  def decode_direction(2), do: :down
  def decode_direction(3), do: :left
  def decode_direction(4), do: :right
end
