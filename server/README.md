# Dogfight server

Server component for the Dogfight battle arena game, developed to have some fun
with game dev and soft-real time distributed systems.

## Features

- Simple game state management
  - Spaceships, bullets, power ups
- Binary protocol for communication
- Early stages, but basic distribution by design, `libcluster` and `horde`
  to handle processes

### TODO

- Authentication, token session and UUID matching on connect
- Cache layer, maybe `Nebulex`
- Some persistence layer, dashboards, lobbies
- Encrypted network communication
- Some observability, metrics

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dogfight` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dogfight, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dogfight>.

