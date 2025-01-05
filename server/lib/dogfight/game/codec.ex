defmodule Dogfight.Game.Codec do
  @moduledoc """
  Generic encoding and decoding behaviour
  """

  alias Dogfight.Game.State

  @callback encode(State.t()) :: binary()
  @callback decode(binary()) :: {:ok, State.t()} | {:error, :codec_error}
end
