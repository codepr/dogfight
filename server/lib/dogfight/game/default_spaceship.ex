defmodule Dogfight.Game.DefaultSpaceship do
  @moduledoc """
  DefaultSpaceship module, represents the main entity of each player, a default
  spaceship without any particular trait, with a base speed of 3 units and base HP
  of 5.
  """

  defmodule Bullet do
    @moduledoc """
    Bullet inner module, represents a bullet of the spaceship entity
    """

    @type t :: %__MODULE__{
            position: Vec2.t(),
            direction: State.direction(),
            active?: boolean()
          }

    defstruct [:position, :direction, :active?]

    alias Dogfight.Game.State
    alias Dogfight.Game.Vec2

    @bullet_base_speed 6

    def new do
      %__MODULE__{
        position: %Vec2{x: 0, y: 0},
        direction: State.idle(),
        active?: false
      }
    end

    def update(%{active?: false} = bullet), do: bullet

    def update(bullet) do
      position = bullet.position

      case bullet.direction do
        :up ->
          %{bullet | position: Vec2.add_y(position, -@bullet_base_speed)}

        :down ->
          %{bullet | position: Vec2.add_y(position, @bullet_base_speed)}

        :left ->
          %{bullet | position: Vec2.add_x(position, -@bullet_base_speed)}

        :right ->
          %{bullet | position: Vec2.add_x(position, @bullet_base_speed)}

        _ ->
          bullet
      end
    end
  end

  @behaviour Dogfight.Game.Spaceship

  alias Dogfight.Game.State
  alias Dogfight.Game.Bullet
  alias Dogfight.Game.Vec2

  @type t :: %__MODULE__{
          position: Vec2.t(),
          hp: non_neg_integer(),
          direction: State.direction(),
          alive?: boolean(),
          bullets: [Bullet.t(), ...]
        }

  defstruct [:position, :hp, :direction, :alive?, :bullets]

  @base_hp 5
  @base_bullet_count 5
  @base_spaceship_speed 3

  def spawn(width, height) do
    %__MODULE__{
      position: Vec2.random(width, height),
      direction: State.idle(),
      hp: @base_hp,
      alive?: true,
      bullets: Stream.repeatedly(&__MODULE__.Bullet.new/0) |> Enum.take(@base_bullet_count)
    }
  end

  @impl true
  def move(spaceship, direction) do
    position = spaceship.position

    updated_position =
      case direction do
        :up -> Vec2.add_y(position, -@base_spaceship_speed)
        :down -> Vec2.add_y(position, @base_spaceship_speed)
        :left -> Vec2.add_x(position, -@base_spaceship_speed)
        :right -> Vec2.add_x(position, @base_spaceship_speed)
      end

    %{spaceship | direction: direction, position: updated_position}
  end

  @impl true
  def shoot(spaceship) do
    bullets =
      spaceship.bullets
      |> Enum.map_reduce(false, fn
        bullet, false when bullet.active? == false ->
          {%{
             bullet
             | active?: true,
               direction: spaceship.direction,
               position: spaceship.position
           }, true}

        bullet, updated ->
          {bullet, updated}
      end)
      |> elem(0)

    %{
      spaceship
      | bullets: bullets
    }
  end

  @impl true
  def update_bullets(%{alive?: false} = spaceship), do: spaceship

  @impl true
  def update_bullets(spaceship) do
    %{spaceship | bullets: Enum.map(spaceship.bullets, &__MODULE__.Bullet.update/1)}
  end
end
