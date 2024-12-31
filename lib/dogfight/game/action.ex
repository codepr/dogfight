defmodule Dogfight.Game.Action do
  @moduledoc false

  alias Dogfight.Encoding.Helpers, as: Encoding

  @type t :: :move_up | :move_down | :move_left | :move_right | :shoot | :idle

  def encode(action) do
    total_length = 5

    Encoding.encode_list([
      {total_length, :double_word},
      {action_to_int(action), :half_word}
    ])
  end

  def decode!(binary) do
    <<_total_length::big-unsigned-integer-size(32), action::big-unsigned-integer-size(8)>> =
      binary

    int_to_action(action)
  end

  defp action_to_int(action) do
    case action do
      :move_up -> 1
      :move_down -> 2
      :move_left -> 3
      :move_right -> 4
      :shoot -> 5
      _ -> 0
    end
  end

  defp int_to_action(intval) do
    case intval do
      1 -> :move_up
      2 -> :move_down
      3 -> :move_left
      4 -> :move_right
      5 -> :shoot
      _ -> :idle
    end
  end
end
