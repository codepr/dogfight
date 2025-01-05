defmodule Dogfight.Game.Codecs.BinaryCodecTest do
  @moduledoc false
  use ExUnit.Case

  alias Dogfight.Game.State, as: GameState
  alias Dogfight.Game.Codecs.BinaryCodec

  describe "encode/1 / decode!/1" do
    test "generic behaviour" do
      game_state = GameState.new()

      assert game_state
             |> BinaryCodec.encode()
             |> BinaryCodec.decode() == {:ok, game_state}
    end

    test "returns an error tuple if decoding fails" do
      garbage = IO.iodata_to_binary("some-garbage")
      assert BinaryCodec.decode(garbage) == {:error, :codec_error}
    end
  end
end
