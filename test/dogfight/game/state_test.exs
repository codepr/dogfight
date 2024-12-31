defmodule Dogfight.Game.StateTest do
  @moduledoc false
  use ExUnit.Case
  alias Dogfight.Game.State, as: GameState

  describe "encode/1 / decode!/1" do
    test "generic behaviour" do
      game_state = GameState.new()

      assert game_state
             |> GameState.encode()
             |> GameState.decode!() == game_state
    end
  end

  describe "spawn_ship/2" do
    test "generate a random ship in the game state" do
      game_state = GameState.new()

      assert {:ok, update_state} = GameState.spawn_ship(game_state, 1)
      assert update_state.active_players == 1

      spawned_ship = Enum.at(update_state.players, 1)
      assert spawned_ship.hp == 5
      assert spawned_ship.coord.x != 0
      assert spawned_ship.coord.y != 0
    end

    test "if already alive, returns the game state unaltered" do
      game_state = GameState.new()

      game_state = %{
        game_state
        | players: Enum.map(game_state.players, fn player -> %{player | alive: true} end)
      }

      assert {:ok, update_state} = GameState.spawn_ship(game_state, 1)
      assert update_state.active_players == 0

      spawned_ship = Enum.at(update_state.players, 1)
      assert spawned_ship.hp == 0
      assert spawned_ship.coord.x == 0
      assert spawned_ship.coord.y == 0
    end
  end

  describe "apply_action/3" do
    test "applies a move action to a ship" do
      game_state = GameState.new()

      game_state = %{
        game_state
        | players: Enum.map(game_state.players, fn player -> %{player | alive: true} end)
      }

      action = :up

      game_state = GameState.apply_action(game_state, action, 0)
      assert Enum.at(game_state.players, 0).direction == :up
    end

    test "applies a shoot action to a ship" do
      game_state = GameState.new()

      game_state = %{
        game_state
        | players: Enum.map(game_state.players, fn player -> %{player | alive: true} end)
      }

      action = :shoot

      game_state = GameState.apply_action(game_state, action, 0)

      [%{bullets: [first_bullet | _rest]} | _rest_players] = game_state.players
      assert first_bullet == %{active: true, coord: %{x: 0, y: 0}, direction: :idle}
    end
  end

  describe "update/1" do
    test "updates all ships in the game state" do
      {:ok, game_state} = GameState.new() |> GameState.spawn_ship(0)

      game_state =
        game_state
        |> GameState.apply_action(:down, 0)
        |> GameState.apply_action(:shoot, 0)

      game_state = GameState.update(game_state)

      [%{alive: alive, bullets: [first_bullet | _rest_bullets]} | _rest] =
        game_state.players

      assert alive
      assert first_bullet.active
    end
  end
end
