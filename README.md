# Phoenix LiveController

[![License](https://img.shields.io/github/license/karolsluszniak/phoenix_live_controller.svg)](https://github.com/karolsluszniak/phoenix_live_controller/blob/master/LICENSE.md)
[![Build status](https://img.shields.io/travis/karolsluszniak/phoenix_live_controller/master.svg)](https://travis-ci.org/karolsluszniak/phoenix_live_controller)
[![Hex version](https://img.shields.io/hexpm/v/phoenix_live_controller.svg)](https://hex.pm/packages/phoenix_live_controller)

**Controller-style abstraction for building multi-action live views on top of Phoenix.LiveView.**

## Installation

Add `phoenix_live_controller` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_live_controller, "~> 0.5.0"}
  ]
end
```

## Learning

- [Introductory article & guide for converting HTML resources to live controllers](http://cloudless.studio/articles/51-controller-style-approach-to-liveview-resources) with [example app](https://github.com/karolsluszniak/phoenix_live_controller_example_app)
- [Phoenix.LiveController docs for detailed explanation & examples of live controllers](https://hexdocs.pm/phoenix_live_controller)
- [Phoenix.LiveView docs for explanation of live view itself](https://hexdocs.pm/phoenix_live_view)

## Benchmarking

Repository includes a benchmark that allows to measure the worst-case impact of using live controllers with plugs on the web app:

```
$ mix run priv/bench/bench.exs
inline compile: 0.038
inline run: 0.026
plug_atom compile: 0.233
plug_atom run: 0.155
plug_func compile: 0.234
plug_func run: 0.148
```
