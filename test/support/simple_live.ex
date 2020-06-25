defmodule SimpleLive do
  use Phoenix.LiveController

  @action_handler true
  def index(socket, _params) do
    socket
  end
end
