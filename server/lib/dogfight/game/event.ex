defmodule Dogfight.Game.Event do
  @moduledoc """
  This structure represents any game event to be applied to a game state to
  transition to a new state
  """

  alias Dogfight.Game.State

  @type t ::
          {:player_connection, State.player_id()}
          | {:player_disconnection, State.player_id()}
          | {:move, {State.player_id(), State.direction()}}
          | {:shoot, State.player_id()}
          | {:pickup_power_up, State.player_id()}
          | {:spawn_power_up, State.power_up_kind()}
          | {:start_game}
          | {:end_game}

  def player_connection(player_id), do: {:player_connection, player_id}
  def player_disconnection(player_id), do: {:player_disconnection, player_id}
  def move(player_id, direction), do: {:move, {player_id, direction}}
  def shoot(player_id), do: {:shoot, player_id}
end
