defmodule Dogfight.Game.Action do
  @moduledoc false

  alias Dogfight.Encoding.Helpers, as: Encoding

  @type direction :: :idle | :up | :down | :left | :right
  @type t :: direction() | :shoot

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
      :up -> 1
      :down -> 2
      :left -> 3
      :right -> 4
      :shoot -> 5
      _ -> 0
    end
  end

  defp int_to_action(intval) do
    case intval do
      1 -> :up
      2 -> :down
      3 -> :left
      4 -> :right
      5 -> :shoot
      _ -> :idle
    end
  end

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
