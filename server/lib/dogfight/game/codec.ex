defmodule Dogfight.Game.Codec do
  @moduledoc """
  Generic encoding and decoding behaviour
  """

  alias Dogfight.Game.State
  alias Dogfight.Game.Event

  @callback encode(State.t()) :: binary()
  @callback decode(binary()) :: {:ok, State.t()} | {:error, :codec_error}

  @callback encode_event(Event.t()) :: binary()
  @callback decode_event(binary()) :: {:ok, Event.t()} | {:error, :codec_error}
end
