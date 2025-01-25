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
            id: non_neg_integer(),
            position: Vec2.t(),
            previous_position: Vec2.t(),
            direction: State.direction(),
            active?: boolean(),
            boundaries: %{width: non_neg_integer(), height: non_neg_integer()}
          }

    defstruct [:id, :position, :previous_position, :direction, :active?, :boundaries]

    alias Dogfight.Game.State
    alias Dogfight.Game.Vec2

    @bullet_base_speed 6

    def new(width, height, index) do
      %__MODULE__{
        id: index,
        position: %Vec2{x: 0, y: 0},
        previous_position: %Vec2{x: 0, y: 0},
        direction: State.idle(),
        active?: false,
        boundaries: %{width: width, height: height}
      }
    end

    def update(%{active?: false} = bullet), do: bullet

    def update(bullet) do
      position = bullet.position

      bullet = %{bullet | previous_position: position}

      bullet =
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

      boundaries_check(bullet)
    end

    defp boundaries_check(%{position: %{x: x}, boundaries: %{width: width}} = bullet)
         when x < 0 or x >= width,
         do: %{bullet | active?: false}

    defp boundaries_check(%{position: %{y: y}, boundaries: %{height: height}} = bullet)
         when y < 0 or y >= height,
         do: %{bullet | active?: false}

    defp boundaries_check(bullet), do: bullet
  end

  @behaviour Dogfight.Game.Spaceship

  alias Dogfight.Game.State
  alias Dogfight.Game.Bullet
  alias Dogfight.Game.Vec2

  @type t :: %__MODULE__{
          position: Vec2.t(),
          radius: non_neg_integer(),
          hp: non_neg_integer(),
          direction: State.direction(),
          alive?: boolean(),
          bullets: [Bullet.t(), ...]
        }

  defstruct [:position, :radius, :hp, :direction, :alive?, :bullets]

  @base_hp 5
  @base_bullet_count 5
  @base_spaceship_speed 3

  def spawn(width, height, x \\ nil, y \\ nil) do
    %__MODULE__{
      position: if(x && y, do: %Vec2{x: x, y: y}, else: Vec2.random(width, height)),
      radius: 2,
      direction: State.idle(),
      hp: @base_hp,
      alive?: true,
      bullets: for(i <- 0..@base_bullet_count, do: __MODULE__.Bullet.new(width, height, i))
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
        :idle -> position
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

  @spec check_collision(Bullet.t(), Vec2.t()) :: boolean()
  def check_collision(%{active: false}), do: false

  def check_collision(%{position: %{x: x, y: y}}, %{x: coord_x, y: coord_y})
      when x == coord_x and y >= coord_y,
      do: true

  def check_collision(%{position: %{x: x, y: y}}, %{x: coord_x, y: coord_y})
      when x >= coord_x and y == coord_y,
      do: true

  def check_collision(_spaceship, _coord), do: false

  def damage(%{alive?: false} = spaceship), do: spaceship

  def damage(spaceship) do
    %{spaceship | hp: spaceship.hp - 1, alive?: spaceship.hp > 1}
  end
end
