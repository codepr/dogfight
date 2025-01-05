defmodule Dogfight.Game.Codecs.Helpers do
  @moduledoc """
  This module provides helper functions for encoding data into binary format.

  The module supports encoding integers of various sizes (half word, word,
  double word, quad word) and binary data.
  """

  @half_word 8
  @word 16
  @double_word 32
  @quad_word 64

  @type word_size :: :half_word | :word | :double_word | :quad_word | :binary
  @type field :: {integer(), word_size()}

  @doc """
  Encodes a list of fields into a binary.

  Each field is a tuple containing an integer and a word size. The word size
  determines the number of bits used to encode the integer.

  ## Parameters

    - fields: A list of tuples where each tuple contains an integer and a word size.

  ## Returns

    - A binary representing the encoded fields.

  ## Examples

      iex> Dogfight.Encoding.Helpers.encode_list([{1, :half_word}, {2, :word}])
      <<1::8, 2::16>>
  """
  @spec encode_list([field(), ...]) :: binary()
  def encode_list(fields) do
    fields
    |> Enum.map(fn {field, word_size} ->
      case word_size do
        :half_word -> encode_half_word(field)
        :word -> encode_word(field)
        :double_word -> encode_double_word(field)
        :quad_word -> encode_quad_word(field)
        :binary -> field
      end
    end)
    |> IO.iodata_to_binary()
  end

  def encode_half_word(data), do: encode_integer(data, @half_word)
  def encode_word(data), do: encode_integer(data, @word)
  def encode_double_word(data), do: encode_integer(data, @double_word)
  def encode_quad_word(data), do: encode_integer(data, @quad_word)

  def encode_integer(true, size), do: encode_integer(1, size)
  def encode_integer(false, size), do: encode_integer(0, size)
  def encode_integer(data, size) when is_integer(data), do: <<data::integer-size(size)>>

  def half_word_byte_size, do: @half_word / @half_word
  def word_byte_size, do: @word / @half_word
  def double_word_byte_size, do: @double_word / @half_word
  def quad_word_byte_size, do: @quad_word / @half_word
end
