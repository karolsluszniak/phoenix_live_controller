defmodule SampleLive.Some.NestedPlug do
  @behaviour Phoenix.LiveController.Plug

  @impl true
  def call(socket) do
    socket
  end

  @impl true
  def call(socket, {_action, _params}) do
    socket
  end
end

defmodule Reusable do
  defmacro __using__(_) do
    quote do
      plug SampleLive.Some.NestedPlug when action == :nonexisting
      plug SampleLive.Some.NestedPlug, {action, params}
    end
  end
end

defmodule SampleLive do
  use Phoenix.LiveController
  alias SampleLive.Some.NestedPlug
  use Reusable

  defmodule BeforeGlobal do
    @behaviour Phoenix.LiveController.Plug

    @impl true
    def call(socket, {name, payload}) do
      assign(socket, :global_plug_called, {name, payload})
    end

    def other(socket, arg) do
      assign(socket, :other_global_plug_called, arg)
    end
  end

  @impl true
  def apply_session(socket, session) do
    if session["user"] == "badguy",
      do: push_redirect(socket, to: "/"),
      else: assign(socket, user: session["user"])
  end

  plug BeforeGlobal, {action || event || message, params || payload}
  plug NestedPlug

  @skip_action :index_with_opts
  plug BeforeGlobal.other(socket, :arg) when action != @skip_action and !message

  plug on_final_mount(socket) when action && connected?(socket) && !mounted?(socket)
  defp on_final_mount(socket) do
    if Map.get(socket.assigns, :final_mount_done) do
      raise "mounting twice?"
    else
      assign(socket, :final_mount_done, true)
    end
  end

  plug :before_action_handler, %{p: params, key: :before_action_handler_called} when action
  plug :before_action_handler, %{p: params, key: :before_action_handler_called_two} when action
  defp before_action_handler(socket, %{p: params, key: key}) do
    history = Map.get(socket.assigns, :plug_history, [])

    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, key, true) |> assign(:plug_history, history ++ [key])
  end

  plug :before_event_handler, params when event
  def before_event_handler(socket, params) do
    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_event_handler_called: true)
  end

  plug :before_message_handler, payload when message
  def before_message_handler(socket, payload) do
    if payload == {:x, :redirect},
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_message_handler_called: true)
  end

  @impl true
  def action_handler(socket, name, params) do
    socket
    |> super(name, params)
    |> case do
      {:ok, socket, opts} -> {:ok, assign(socket, :action_handler_override, true), opts}
      socket -> assign(socket, :action_handler_override, true)
    end
  end

  @impl true
  def event_handler(socket, name, params) do
    socket
    |> super(name, params)
    |> assign(:event_handler_override, true)
  end

  @impl true
  def message_handler(socket, name, message) do
    socket
    |> super(name, message)
    |> assign(:message_handler_override, true)
  end

  @action_handler true
  def index(socket, params) do
    assign(socket, items: [params["first_item"], :second])
  end

  @action_handler true
  def index_with_opts(socket, params) do
    socket = assign(socket, items: [params["first_item"], :second])
    {:ok, socket, temporary_assigns: [items: []]}
  end

  @event_handler true
  def create(socket, params) do
    assign(socket, items: socket.assigns.items ++ [params["new_item"]])
  end

  @message_handler true
  def x(socket, _message) do
    assign(socket, called: true)
  end
end
