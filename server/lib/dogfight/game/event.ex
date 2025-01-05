defmodule Dogfight.Game.Event do
  @moduledoc false

  alias Dogfight.Game.State

  @type t ::
          {:move, State.player_id(), State.direction()}
          | {:shoot, State.player_id()}
          | {:pickup_powerup, State.player_id()}
          | {:spawn_powerup, State.power_up()}
          | {:start_game}
          | {:end_game}
end
