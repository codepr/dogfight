defmodule Dogfight.Game.Spaceship do
  @moduledoc """
  Spaceship behaviour
  """

  alias Dogfight.Game.State

  @type t :: any()

  @callback move(t(), State.direction()) :: t()
  @callback shoot(t()) :: t()
  @callback update_bullets(t()) :: t()
end
