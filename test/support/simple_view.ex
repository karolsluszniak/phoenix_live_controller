defmodule SimpleView do
  def render(name, assigns) do
    {:rendered, name, assigns}
  end
end
