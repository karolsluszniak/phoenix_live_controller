defmodule Phoenix.LiveController.Plug do
  @moduledoc """
  Defines plug module for use with Phoenix live controllers.
  """

  @callback call(socket :: Socket.t()) ::
              Socket.t()
              | {:ok, Socket.t()}
              | {:ok, Socket.t(), keyword()}
              | {:noreply, Socket.t()}
              | {:reply, term(), Socket.t()}
end
