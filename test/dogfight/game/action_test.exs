defmodule Dogfight.Game.ActionTest do
  @moduledoc false
  use ExUnit.Case
  alias Dogfight.Game.Action, as: GameAction

  describe "encode/1 / decode!/1" do
    test "generic behaviour" do
      assert [:idle, :move_up, :move_down, :move_left, :move_right, :shoot]
             |> Enum.map(&GameAction.encode/1)
             |> Enum.map(&GameAction.decode!/1)
             |> Enum.all?()
    end
  end
end
