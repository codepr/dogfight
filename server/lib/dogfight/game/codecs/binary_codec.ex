defmodule Dogfight.Game.Codecs.BinaryCodec do
  @moduledoc """
  Binary implementation of the game econding and decoding logic

  Handles

  - Game state
  - Game event
  """

  @behaviour Dogfight.Game.Codec

  alias Dogfight.Game.Codecs.Helpers
  alias Dogfight.Game.State
  alias Dogfight.Game.Vec2

  @power_up_size Helpers.double_word_size() * 2 + Helpers.half_word_size()
  @bullet_size Helpers.double_word_size() * 2 + Helpers.half_word_size() * 2
  # (32 bytes and 4 hyphens as per UUID)
  @player_id_size Helpers.double_word_size() + 4
  @spaceship_size @player_id_size + 5 * @bullet_size +
                    3 * Helpers.double_word_size() + 2 * Helpers.half_word_size()

  @impl true
  def encode_event(event) do
    case event do
      {:move, {player_id, direction}} ->
        Helpers.encode_list([
          {event_to_int(:move), :half_word},
          {direction_to_int(direction), :half_word},
          {player_id, :binary}
        ])

      {player_action, player_id}
      when player_action in [:player_connection, :player_disconnection, :shoot] ->
        Helpers.encode_list([
          {event_to_int(player_action), :half_word},
          {player_id, :binary}
        ])
    end
  end

  @impl true
  def decode_event(binary) do
    <<action::big-integer-size(8), rest::binary>> = binary

    action = int_to_event(action)

    case action do
      :move ->
        <<direction::big-integer-size(8), player_id::binary-size(@player_id_size)>> =
          rest

        {:ok, {action, {player_id, int_to_direction(direction)}}}

      player_action when player_action in [:player_connection, :player_disconnection, :shoot] ->
        <<player_id::binary-size(@player_id_size)>> = rest

        {:ok, {action, player_id}}
    end
  rescue
    _e -> {:error, :codec_error}
  end

  # For now we can just handle the basic events from the
  # client, which are only move and shoot really
  defp event_to_int(action) do
    case action do
      :player_connection -> 0
      :player_disconnection -> 1
      :move -> 2
      :shoot -> 3
    end
  end

  defp int_to_event(intval) do
    case intval do
      0 -> :player_connection
      1 -> :player_disconnection
      2 -> :move
      3 -> :shoot
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

    binary_ships_byte_size = byte_size(binary_ships)
    binary_power_ups_byte_size = byte_size(binary_power_ups)

    total_length =
      binary_ships_byte_size +
        binary_power_ups_byte_size +
        Helpers.double_word_size() +
        Helpers.half_word_size() +
        Helpers.word_size()

    Helpers.encode_list([
      {total_length, :double_word},
      {status_to_int(game_state.status), :half_word},
      {binary_power_ups_byte_size, :word},
      {binary_power_ups, :binary},
      {binary_ships, :binary}
    ])
  end

  defp encode_spaceship(player_id, spaceship) do
    direction = direction_to_int(spaceship.direction)

    binary_bullets =
      spaceship.bullets
      |> Enum.map(&encode_bullet/1)
      |> IO.iodata_to_binary()

    %{x: x, y: y} = spaceship.position

    Helpers.encode_list([
      {x, :double_word},
      {y, :double_word},
      {spaceship.hp, :half_word},
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
    direction = direction_to_int(bullet.direction)

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
    <<_total_length::big-integer-size(32), status::big-integer-size(8),
      power_ups_len::big-integer-size(16),
      rest::binary>> =
      binary

    <<power_ups_bin::binary-size(power_ups_len), player_records::binary>> = rest

    power_ups =
      power_ups_bin
      |> chunk_bits(@power_up_size)
      |> Enum.map(&decode_power_up!/1)

    players =
      player_records
      |> chunk_bits(@spaceship_size)
      |> Enum.map(&decode_spaceship!/1)
      |> Map.new()

    {:ok,
     %State{
       players: players,
       power_ups: power_ups,
       status: int_to_status(status)
     }}
  rescue
    # TODO add custom errors
    _e -> {:error, :codec_error}
  end

  defp decode_power_up!(
         <<power_up_x::big-integer-size(32), power_up_y::big-integer-size(32),
           power_up_kind::big-integer-size(8)>>
       ) do
    %{position: %Vec2{x: power_up_x, y: power_up_y}, kind: int_to_power_up(power_up_kind)}
  end

  defp decode_spaceship!(
         <<x::big-integer-size(32), y::big-integer-size(32), hp::big-integer-size(8),
           alive::big-integer-size(8), direction::big-integer-size(8),
           player_id::binary-size(@player_id_size), bullets::binary>>
       ) do
    {player_id,
     %{
       position: %Vec2{x: x, y: y},
       hp: hp,
       direction: int_to_direction(direction),
       alive?: alive == 1,
       bullets:
         bullets
         |> chunk_bits(@bullet_size)
         |> Enum.map(&decode_bullet!/1)
     }}
  end

  defp decode_bullet!(
         <<x::big-integer-size(32), y::big-integer-size(32), active::big-integer-size(8),
           direction::big-integer-size(8)>>
       ) do
    %{
      position: %{x: x, y: y},
      active?: if(active == 0, do: false, else: true),
      direction: int_to_direction(direction)
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

  defp status_to_int(nil), do: 0
  defp status_to_int(:in_progress), do: 1
  defp status_to_int(:closed), do: 2

  defp int_to_status(0), do: nil
  defp int_to_status(1), do: :in_progress
  defp int_to_status(2), do: :closed

  def direction_to_int(:idle), do: 0
  def direction_to_int(:up), do: 1
  def direction_to_int(:down), do: 2
  def direction_to_int(:left), do: 3
  def direction_to_int(:right), do: 4

  def int_to_direction(0), do: :idle
  def int_to_direction(1), do: :up
  def int_to_direction(2), do: :down
  def int_to_direction(3), do: :left
  def int_to_direction(4), do: :right
end
