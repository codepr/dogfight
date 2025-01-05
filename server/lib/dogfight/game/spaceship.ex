defmodule Dogfight.Game.Spaceship do
  @moduledoc """
  Spaceship behaviour
  """

  alias Dogfight.Game.Action

  @type t :: any()

  @callback spawn(integer(), integer()) :: t()
  @callback move(t(), Action.direction()) :: t()
  @callback shoot(t()) :: t()
  @callback update_bullets(t()) :: t()
end
