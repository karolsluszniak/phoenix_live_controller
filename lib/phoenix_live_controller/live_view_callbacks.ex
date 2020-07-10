defmodule Phoenix.LiveController.LiveViewCallbacks do
  @moduledoc false

  import Phoenix.LiveController
  alias Phoenix.LiveController.{ControllerState, Errors}
  alias Phoenix.LiveView.Socket

  def mount(module, _params, session, socket) do
    action = socket.assigns[:live_action] || Errors.raise_no_action_assign(module)

    unless Enum.member?(module.__live_controller__(:actions), action),
      do: Errors.raise_no_action_handler(module, action)

    opts = Keyword.fetch!(module.__live_controller__(:action_mount_opts), action)
    wrapper = if opts, do: &{:ok, &1, opts}, else: &{:ok, &1}

    socket
    |> initialize_controller_state(session)
    |> wrap_socket(wrapper)
  end

  defp initialize_controller_state(%{controller: _}, _) do
    Errors.raise_controller_already_in_socket()
  end

  defp initialize_controller_state(socket, session) do
    Map.put_new(socket, :controller, %ControllerState{mounted?: false, session: session})
  end

  def handle_params(module, before_callback, params, url, socket) do
    action = socket.assigns.live_action

    socket
    |> case do
      socket = %{controller: _} -> update_controller_state(socket, url: url)
      # fail on non-mounted socket later
      socket -> socket
    end
    |> before_callback.(action, params)
    |> chain(&module.action_handler(&1, action, params))
    |> wrap_socket(&{:noreply, &1})
    |> ensure_proper_return_value(module, {:action, action})
    |> update_controller_state(mounted?: true)
  end

  def handle_event(module, before_callback, event_string, params, socket) do
    unless Enum.any?(module.__live_controller__(:events), &(to_string(&1) == event_string)),
      do: Errors.raise_no_event_handler(module, event_string)

    event = String.to_atom(event_string)

    socket
    |> before_callback.(event, params)
    |> chain(&module.event_handler(&1, event, params))
    |> maybe_wrap_and_clear_reply_payload()
    |> wrap_socket(&{:noreply, &1})
    |> ensure_proper_return_value(module, {:event, event})
  end

  defp maybe_wrap_and_clear_reply_payload(socket = %{controller: %{reply_payload: nil}}),
    do: socket

  defp maybe_wrap_and_clear_reply_payload(socket = %{controller: %{reply_payload: payload}}),
    do: {:reply, payload, update_controller_state(socket, reply_payload: nil)}

  defp maybe_wrap_and_clear_reply_payload(value),
    do: value

  def handle_message(module, before_callback, message_payload, socket) do
    message_key = extract_message_key(message_payload)

    unless message_key,
      do: Errors.raise_no_message_info(module, message_payload)

    unless Enum.member?(module.__live_controller__(:messages), message_key),
      do: Errors.raise_no_message_handler(module, message_key, message_payload)

    socket
    |> before_callback.(message_key, message_payload)
    |> chain(&module.message_handler(&1, message_key, message_payload))
    |> wrap_socket(&{:noreply, &1})
    |> ensure_proper_return_value(module, {:message, message_key})
  end

  defp extract_message_key(message_payload) do
    cond do
      is_atom(message_payload) ->
        message_payload

      is_tuple(message_payload) and is_atom(elem(message_payload, 0)) ->
        elem(message_payload, 0)

      true ->
        nil
    end
  end

  defp update_controller_state({:noreply, socket}, changes),
    do: {:noreply, update_controller_state(socket, changes)}

  defp update_controller_state({:reply, payload, socket}, changes),
    do: {:reply, payload, update_controller_state(socket, changes)}

  defp update_controller_state(socket = %{controller: controller}, changes),
    do: Map.put(socket, :controller, Map.merge(controller, Map.new(changes)))

  defp ensure_proper_return_value(val = {:noreply, socket = %Socket{}}, module, context) do
    ensure_proper_socket_state(socket, module, context)
    val
  end

  defp ensure_proper_return_value(
         val = {:reply, _, socket = %Socket{}},
         module,
         context = {:event, _}
       ) do
    ensure_proper_socket_state(socket, module, context)
    val
  end

  defp ensure_proper_return_value(val, module, context) do
    Errors.raise_invalid_return_value(module, context, val)
  end

  defp ensure_proper_socket_state(socket = %Socket{}, module, context) do
    ensure_controller_attached(socket, module, context)
    ensure_no_reply_payload(socket, module, context)
  end

  defp ensure_controller_attached(%{controller: _}, _module, _context) do
    :ok
  end

  defp ensure_controller_attached(_, module, context) do
    Errors.raise_no_controller_in_socket(module, context)
  end

  defp ensure_no_reply_payload(%{controller: %{reply_payload: nil}}, _module, _context) do
    :ok
  end

  defp ensure_no_reply_payload(_socket, module, context) do
    Errors.raise_reply_for_noreply_handler(module, context)
  end

  defp wrap_socket(socket = %Socket{}, wrapper), do: wrapper.(socket)
  defp wrap_socket(misc, _wrapper), do: misc
end
