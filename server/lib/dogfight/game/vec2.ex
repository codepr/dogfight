defmodule Dogfight.Game.Vec2 do
  @moduledoc """
  Utility module to perform operations on Vector 2D
  """

  @type t :: %__MODULE__{
          x: integer(),
          y: integer()
        }

  defstruct [:x, :y]

  def random(x, y) do
    %__MODULE__{x: :rand.uniform(x), y: :rand.uniform(y)}
  end

  def add(v1, v2) do
    %__MODULE__{x: v1.x + v2.x, y: v1.y + v2.y}
  end

  def add_x(v, x) do
    %__MODULE__{x: v.x + x, y: v.y}
  end

  def add_y(v, y) do
    %__MODULE__{x: v.x, y: v.y + y}
  end
end
