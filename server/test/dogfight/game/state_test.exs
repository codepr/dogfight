defmodule Dogfight.Game.StateTest do
  @moduledoc false
  use ExUnit.Case
  alias Dogfight.Game.Event, as: GameEvent
  alias Dogfight.Game.State, as: GameState

  describe "add_player/2" do
    test "generate a random spaceship in the game state for a new player" do
      game_state = GameState.new()

      assert {:ok, update_state} = GameState.add_player(game_state, "id")

      spawned_ship = Map.fetch!(update_state.players, "id")
      assert spawned_ship.hp == 5
      assert spawned_ship.position.x != 0
      assert spawned_ship.position.y != 0
    end

    test "if already alive, returns the game state unaltered" do
      game_state = GameState.new()

      game_state = %{
        game_state
        | players: %{"id" => %{alive?: true, hp: 0, position: %{x: 5, y: 5}}}
      }

      assert {:ok, update_state} = GameState.add_player(game_state, "id")

      spawned_ship = Map.fetch!(update_state.players, "id")
      assert spawned_ship.hp == 0
      assert spawned_ship.position.x == 5
      assert spawned_ship.position.y == 5
    end

    test "if already exits but not alive, returns an error" do
      game_state = GameState.new()

      game_state = %{game_state | players: %{"id" => %{alive?: false}}}

      assert {:error, :dismissed_ship} = GameState.add_player(game_state, "id")
    end
  end

  describe "apply_event/2" do
    test "applies a move action to a spaceship" do
      move_event = GameEvent.move("player_id", :up)

      {:ok, game_state} = GameState.new() |> GameState.add_player("player_id")

      assert {:ok, game_state} = GameState.apply_event(game_state, move_event)

      assert game_state.players["player_id"].direction == :up
    end

    test "applies a shoot action to a ship" do
      shoot_event = GameEvent.shoot("player_id")

      {:ok, game_state} = GameState.new() |> GameState.add_player("player_id")
      {:ok, game_state} = GameState.apply_event(game_state, shoot_event)

      %{bullets: [first_bullet | _rest]} = game_state.players["player_id"]

      assert %Dogfight.Game.DefaultSpaceship.Bullet{
               active?: true,
               position: _position,
               direction: :idle
             } = first_bullet
    end

    test "errors when no player is found" do
      {:ok, game_state} = GameState.new() |> GameState.add_player("player_id")

      assert {:error, :dismissed_ship} =
               GameState.apply_event(game_state, GameEvent.move("player_id-2", :down))
    end
  end

  describe "update/1" do
    test "updates all ships in the game state" do
      player_id = "player_id"
      {:ok, game_state} = GameState.new() |> GameState.add_player(player_id)

      {:ok, game_state} = GameState.apply_event(game_state, GameEvent.move(player_id, :down))
      {:ok, game_state} = GameState.apply_event(game_state, GameEvent.shoot(player_id))

      game_state = GameState.update(game_state)

      %{alive?: alive, bullets: [first_bullet | _rest_bullets]} = game_state.players[player_id]

      assert alive
      assert first_bullet.active?
    end

    test "updates active bullets in the game state" do
      player_id = "player_id"
      {:ok, game_state} = GameState.new() |> GameState.add_player(player_id)

      {:ok, game_state} = GameState.apply_event(game_state, GameEvent.move(player_id, :down))
      {:ok, game_state} = GameState.apply_event(game_state, GameEvent.shoot(player_id))

      %Dogfight.Game.DefaultSpaceship{
        direction: :down,
        alive?: true,
        bullets: [
          %Dogfight.Game.DefaultSpaceship.Bullet{
            position: %Dogfight.Game.Vec2{y: origin_y},
            direction: :down,
            active?: true
          }
          | _bullets
        ]
      } = game_state.players[player_id]

      game_state =
        game_state
        |> GameState.update()
        |> GameState.update()
        |> GameState.update()

      %{alive?: alive, bullets: [first_bullet | _rest_bullets]} = game_state.players[player_id]

      assert alive
      assert first_bullet.active?
      assert first_bullet.position.y == origin_y + 18
    end
  end
end
