defmodule Dogfight.Game.StateTest do
  @moduledoc false
  use ExUnit.Case
  alias Dogfight.Game.State, as: GameState

  describe "serialize/1 / deserialize!/1" do
    test "generic behaviour" do
      game_state = GameState.new()

      assert game_state
             |> GameState.serialize()
             |> GameState.deserialize!() == game_state
    end
  end

  describe "spawn_ship/2" do
    test "generate a random ship in the game state" do
      game_state = GameState.new()

      game_state = %{
        game_state
        | players: Enum.map(game_state.players, fn player -> %{player | alive: true} end)
      }

      assert {:ok, update_state} = GameState.spawn_ship(game_state, 1)
      assert update_state.active_players == 1

      spawned_ship = Enum.at(update_state.players, 1)
      assert spawned_ship.hp == 5
      assert spawned_ship.coord.x != 0
      assert spawned_ship.coord.y != 0
    end

    test "bubbles up an error in case of an unalive ship" do
      game_state = GameState.new()

      assert {:error, :dimissed_ship} == GameState.spawn_ship(game_state, 1)
    end
  end
end
