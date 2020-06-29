defmodule SampleLive.Some.NestedPlug do
  @behaviour Phoenix.LiveController.Plug

  @impl true
  def call(socket) do
    socket
  end
end

defmodule Reusable do
  defmacro __using__(_) do
    quote do
      plug SampleLive.Some.NestedPlug when action == :nonexisting
    end
  end
end

defmodule SampleLive do
  use Phoenix.LiveController
  alias SampleLive.Some.NestedPlug
  use Reusable

  defmodule BeforeGlobal do
    def call(socket, {name, payload}) do
      assign(socket, :global_plug_called, {name, payload})
    end

    def other(socket, arg) do
      assign(socket, :other_global_plug_called, arg)
    end
  end

  plug fetch_user(socket) when action && !mounted?(socket)

  defp fetch_user(socket) do
    user = get_session(socket, :user)

    if user == "badguy",
      do: push_redirect(socket, to: "/"),
      else: assign(socket, user: user)
  end

  plug BeforeGlobal.call(socket, {name, params || message})
  plug NestedPlug

  @skip_action :index_with_opts
  plug BeforeGlobal.other(socket, :arg) when action != @skip_action and !message

  plug on_final_mount(socket)
       when action && connected?(socket) && !mounted?(socket) && local_check?(socket)

  defp on_final_mount(socket) do
    if Map.get(socket.assigns, :final_mount_done) do
      raise "mounting twice?"
    else
      assign(socket, :final_mount_done, true)
    end
  end

  defp local_check?(_socket) do
    true
  end

  plug :on_final_mount_atom when action && connected?(socket) && !mounted?(socket)

  defp on_final_mount_atom(socket) do
    if Map.get(socket.assigns, :final_mount_done_2) do
      raise "mounting twice?"
    else
      assign(socket, :final_mount_done_2, true)
    end
  end

  plug before_action_handler(socket, %{p: params, key: :before_action_handler_called}) when action

  plug before_action_handler(socket, %{p: params, key: :before_action_handler_called_two})
       when action

  defp before_action_handler(socket, %{p: params, key: key}) do
    history = Map.get(socket.assigns, :plug_history, [])

    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, key, true) |> assign(:plug_history, history ++ [key])
  end

  plug before_event_handler(socket, params) when event

  def before_event_handler(socket, params) do
    if params["redirect"],
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_event_handler_called: true)
  end

  plug before_message_handler(socket, message) when message

  def before_message_handler(socket, message) do
    if message == {:x, :redirect},
      do: push_redirect(socket, to: "/"),
      else: assign(socket, before_message_handler_called: true)
  end

  @impl true
  def action_handler(socket, name, params) do
    socket
    |> super(name, params)
    |> assign(:action_handler_override, true)
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
  @action_mount_opts temporary_assigns: [items: []]
  def index_with_opts(socket, params) do
    assign(socket, items: [params["first_item"], :second])
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
