defmodule SampleLive do
  use Phoenix.LiveController

  @impl true
  def apply_session(socket, session) do
    if session["user"] == "badguy",
      do: push_redirect(socket, to: "/"),
      else: assign(socket, user: session["user"])
  end

  @impl true
  def before_action_handler(socket, _name, params) do
    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_action_handler_called: true)
  end

  @impl true
  def action_handler(socket, name, params) do
    socket
    |> super(name, params)
    |> assign(:action_handler_override, true)
  end

  @impl true
  def before_event_handler(socket, _name, params) do
    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_event_handler_called: true)
  end

  @impl true
  def event_handler(socket, name, params) do
    socket
    |> super(name, params)
    |> assign(:event_handler_override, true)
  end

  @action_handler true
  def index(socket, params) do
    assign(socket, items: [params["first_item"], :second])
  end

  @event_handler true
  def create(socket, params) do
    assign(socket, items: socket.assigns.items ++ [params["new_item"]])
  end
end
