defmodule DogfightTest do
  use ExUnit.Case
  doctest Dogfight

  test "greets the world" do
    assert Dogfight.hello() == :world
  end
end
