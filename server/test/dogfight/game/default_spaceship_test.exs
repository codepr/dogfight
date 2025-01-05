defmodule Dogfight.Game.DefaultSpaceshipTest do
  @moduledoc false

  use ExUnit.Case
  alias Dogfight.Game.DefaultSpaceship
  alias Dogfight.Game.Vec2

  describe "spawn/2" do
    test "generate a random spaceship" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      assert spaceship.alive?
      assert spaceship.hp == 5
      assert spaceship.position.x != 0
      assert spaceship.position.y != 0
      assert spaceship.direction == :idle
    end
  end

  describe "move/2" do
    test "supports up direction" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{x: original_x, y: original_y} = spaceship.position

      updated_spaceship = DefaultSpaceship.move(spaceship, :up)

      assert updated_spaceship.direction == :up
      assert updated_spaceship.position == %Vec2{x: original_x, y: original_y - 3}
    end

    test "supports down direction" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{x: original_x, y: original_y} = spaceship.position

      updated_spaceship = DefaultSpaceship.move(spaceship, :down)

      assert updated_spaceship.direction == :down
      assert updated_spaceship.position == %Vec2{x: original_x, y: original_y + 3}
    end

    test "supports left direction" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{x: original_x, y: original_y} = spaceship.position

      updated_spaceship = DefaultSpaceship.move(spaceship, :left)

      assert updated_spaceship.direction == :left
      assert updated_spaceship.position == %Vec2{x: original_x - 3, y: original_y}
    end

    test "supports right direction" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{x: original_x, y: original_y} = spaceship.position

      updated_spaceship = DefaultSpaceship.move(spaceship, :right)

      assert updated_spaceship.direction == :right
      assert updated_spaceship.position == %Vec2{x: original_x + 3, y: original_y}
    end
  end

  describe "shoot/1" do
    test "shoot the first available bullet" do
      spaceship =
        DefaultSpaceship.spawn(800, 600)
        |> update_in([Access.key!(:bullets), Access.at!(0)], fn bullet ->
          %{bullet | active?: true}
        end)

      updated_spaceship = DefaultSpaceship.shoot(spaceship)

      assert Enum.count(updated_spaceship.bullets, & &1.active?) == 2
    end
  end

  describe "update_bullets/1" do
    test "updates only active bullets" do
      spaceship =
        DefaultSpaceship.spawn(800, 600)
        |> DefaultSpaceship.move(:up)
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.update_bullets()

      assert Enum.count(spaceship.bullets, & &1.active?) == 2

      [bullet_1, bullet_2 | _bullets] = spaceship.bullets

      assert bullet_1.position.x != 0
      assert bullet_1.position.y != 0
      assert bullet_2.position.x != 0
      assert bullet_2.position.y != 0
    end

    test "supports moving the bullets :up" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{position: %{x: origin_x, y: origin_y}} = spaceship = DefaultSpaceship.move(spaceship, :up)

      spaceship =
        spaceship
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.update_bullets()

      assert hd(spaceship.bullets) == %Dogfight.Game.DefaultSpaceship.Bullet{
               position: %Dogfight.Game.Vec2{x: origin_x, y: origin_y - 6},
               direction: :up,
               active?: true
             }
    end

    test "supports moving the bullets :down" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{position: %{x: origin_x, y: origin_y}} =
        spaceship = DefaultSpaceship.move(spaceship, :down)

      spaceship =
        spaceship
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.update_bullets()

      assert hd(spaceship.bullets) == %Dogfight.Game.DefaultSpaceship.Bullet{
               position: %Dogfight.Game.Vec2{x: origin_x, y: origin_y + 6},
               direction: :down,
               active?: true
             }
    end

    test "supports moving the bullets :left" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{position: %{x: origin_x, y: origin_y}} =
        spaceship = DefaultSpaceship.move(spaceship, :left)

      spaceship =
        spaceship
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.update_bullets()

      assert hd(spaceship.bullets) == %Dogfight.Game.DefaultSpaceship.Bullet{
               position: %Dogfight.Game.Vec2{x: origin_x - 6, y: origin_y},
               direction: :left,
               active?: true
             }
    end

    test "supports moving the bullets :right" do
      spaceship = DefaultSpaceship.spawn(800, 600)

      %{position: %{x: origin_x, y: origin_y}} =
        spaceship = DefaultSpaceship.move(spaceship, :right)

      spaceship =
        spaceship
        |> DefaultSpaceship.shoot()
        |> DefaultSpaceship.update_bullets()

      assert hd(spaceship.bullets) == %Dogfight.Game.DefaultSpaceship.Bullet{
               position: %Dogfight.Game.Vec2{x: origin_x + 6, y: origin_y},
               direction: :right,
               active?: true
             }
    end
  end
end
