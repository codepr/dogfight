defmodule Dogfight.IndexAgent do
  @moduledoc """
  Simple agent to generate monotonic increasing indexes for connecting players,
  they will be used as player ids as a first extremely basic iteration, later we
  may prefer to adopt some proper UUID.
  """
  use Agent

  def start_link(_initial_value) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def next_id do
    Agent.get_and_update(__MODULE__, fn index ->
      {index, index + 1}
    end)
  end
end
