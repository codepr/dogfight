defmodule Dogfight.Game.StateTest do
  @moduledoc false
  use ExUnit.Case
  alias Dogfight.Game.State, as: GameState

  describe "serialize/1 / deserialize!/1" do
    game_state = GameState.new()

    assert game_state
           |> GameState.serialize()
           |> GameState.deserialize!() == game_state
  end
end
