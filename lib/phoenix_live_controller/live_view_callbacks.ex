defmodule Phoenix.LiveController.LiveViewCallbacks do
  @moduledoc false

  import Phoenix.LiveController
  alias Phoenix.LiveController.ControllerState

  def mount(module, _params, session, socket) do
    action =
      socket.assigns[:live_action] ||
        raise """
        #{inspect(module)} called without action.

        Make sure to mount it via route that specifies action, e.g. for :index action:

            live "/some_url", #{inspect(module)}, :index

        """

    unless Enum.member?(module.__live_controller__(:actions), action),
      do:
        raise("""
        #{inspect(module)} doesn't implement action handler for #{inspect(action)} action.

        Make sure that #{action} function is defined and annotated as action handler:

            @action_handler true
            def #{action}(socket, params) do
              # ...
            end

        """)

    opts = Keyword.fetch!(module.__live_controller__(:action_mount_opts), action)
    wrapper = if opts, do: &{:ok, &1, opts}, else: &{:ok, &1}

    socket
    |> initialize_controller_state(session)
    |> wrap_socket(wrapper)
  end

  defp initialize_controller_state(%{controller: _}, _) do
    raise("""
    Phoenix.LiveView.Socket struct already includes the :controller key.

    This means that you're using Phoenix.LiveView version incompatible with Phoenix.LiveController
    and that Phoenix.LiveController needs to be updated.
    """)
  end

  defp initialize_controller_state(socket, session) do
    Map.put_new(socket, :controller, %ControllerState{mounted?: false, session: session})
  end

  def handle_params(module, before_callback, params, url, socket) do
    action = socket.assigns.live_action

    socket
    |> update_controller_state(url: url)
    |> before_callback.(action, params)
    |> chain(&module.action_handler(&1, action, params))
    |> update_controller_state(mounted?: true)
    |> wrap_socket(&{:noreply, &1})
  end

  defp update_controller_state({:noreply, socket}, changes) do
    {:noreply, update_controller_state(socket, changes)}
  end

  defp update_controller_state(socket, changes) do
    Map.put(socket, :controller, Map.merge(socket.controller, Map.new(changes)))
  end

  def handle_event(module, before_callback, event_string, params, socket) do
    unless Enum.any?(module.__live_controller__(:events), &(to_string(&1) == event_string)),
      do:
        raise("""
        #{inspect(module)} doesn't implement event handler for #{inspect(event_string)} event.

        Make sure that #{event_string} function is defined and annotated as event handler:

            @event_handler true
            def #{event_string}(socket, params) do
              # ...
            end

        """)

    event = String.to_atom(event_string)

    socket
    |> before_callback.(event, params)
    |> chain(&module.event_handler(&1, event, params))
    |> wrap_socket(&{:noreply, &1})
  end

  def handle_message(module, before_callback, message_payload, socket) do
    message_key =
      cond do
        is_atom(message_payload) ->
          message_payload

        is_tuple(message_payload) and is_atom(elem(message_payload, 0)) ->
          elem(message_payload, 0)

        true ->
          nil
      end

    unless message_key,
      do:
        raise("""
        Message #{inspect(message_payload)} cannot be handled by message handler and
        #{inspect(module)} doesn't implement handle_info/3 that would handle it instead.

        Make sure that appropriate handle_info/3 function matching this message is defined:

            def handle_info(message, socket) do
              # ...
            end

        """)

    unless Enum.member?(module.__live_controller__(:messages), message_key),
      do:
        raise("""
        #{inspect(module)} doesn't implement message handler for #{inspect(message_payload)} message.

        Make sure that #{message_key} function is defined and annotated as message handler:

            @message_handler true
            def #{message_key}(socket, message) do
              # ...
            end

        """)

    socket
    |> before_callback.(message_key, message_payload)
    |> chain(&module.message_handler(&1, message_key, message_payload))
    |> wrap_socket(&{:noreply, &1})
  end

  defp wrap_socket(socket = %Phoenix.LiveView.Socket{}, wrapper), do: wrapper.(socket)
  defp wrap_socket(misc, _wrapper), do: misc
end
