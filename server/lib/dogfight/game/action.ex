defmodule Dogfight.Game.Action do
  @moduledoc false

  alias Dogfight.Game.Codecs.Helpers, as: Encoding
  alias Dogfight.Game.Codecs.BinaryCodec
  alias Dogfight.Game.State

  @type t ::
          {:move, State.player_id(), State.direction()}
          | {:shoot, State.player_id()}
          | {:pickup_powerup, State.player_id()}
          | {:spawn_powerup, State.power_up()}
          | {:start_game}
          | {:end_game}

  def encode(action) do
    total_length = 5

    Encoding.encode_list([
      {total_length, :double_word},
      {action_to_int(action), :half_word}
    ])
  end

  # TODO remove total length
  def decode!(binary) do
    <<_total_length::big-unsigned-integer-size(32), action::big-unsigned-integer-size(8)>> =
      binary

    int_to_action(action)
  end

  defp action_to_int(action) do
    case action do
      :shoot -> 5
      direction -> BinaryCodec.encode_direction(direction)
    end
  end

  defp int_to_action(intval) do
    case intval do
      5 -> :shoot
      direction -> BinaryCodec.decode_direction(direction)
    end
  end
end
