defmodule Phoenix.LiveController.Errors do
  @moduledoc false

  def raise_no_action_assign(module) do
    raise """
    #{inspect(module)} called without action.

    Make sure to mount it via route that specifies action, e.g. for :index action:

        live "/some_url", #{inspect(module)}, :index

    """
  end

  def raise_no_action_handler(module, action) do
    raise("""
    #{inspect(module)} doesn't implement action handler for #{inspect(action)} action.

    Make sure that #{action} function is defined and annotated as action handler:

        @action_handler true
        def #{action}(socket, params) do
          # ...
        end

    """)
  end

  def raise_no_event_handler(module, event_string) do
    raise("""
    #{inspect(module)} doesn't implement event handler for #{inspect(event_string)} event.

    Make sure that #{event_string} function is defined and annotated as event handler:

        @event_handler true
        def #{event_string}(socket, params) do
          # ...
        end

    """)
  end

  def raise_controller_already_in_socket do
    raise("""
    Socket struct already includes the :controller key.

    This means that you're using Phoenix.LiveView version incompatible with Phoenix.LiveController
    and that Phoenix.LiveController needs to be updated.
    """)
  end

  def raise_no_message_info(module, message_payload) do
    raise("""
    Message #{inspect(message_payload)} cannot be handled by message handler and
    #{inspect(module)} doesn't implement handle_info/3 that would handle it instead.

    Make sure that appropriate handle_info/3 function matching this message is defined:

        def handle_info(message, socket) do
          # ...
        end

    """)
  end

  def raise_no_message_handler(module, message_key, message_payload) do
    raise("""
    #{inspect(module)} doesn't implement message handler for #{inspect(message_payload)} message.

    Make sure that #{message_key} function is defined and annotated as message handler:

        @message_handler true
        def #{message_key}(socket, message) do
          # ...
        end

    """)
  end

  def raise_invalid_return_value(module, context, val) do
    raise("""
    #{inspect(module)} returned unexpected value when handling #{error_context_to_string(context)}:

    #{inspect(val, pretty: true)}

    You can only return socket, optionally wrapped in {:noreply, socket} tuple
    or, when handling events, in {:reply, payload, socket} tuple.

    """)
  end

  def raise_no_controller_in_socket(module, context) do
    raise("""
    #{inspect(module)} unexpectedly received socket without controller state when handling
    #{error_context_to_string(context)}.

    This means that one of LiveView callbacks was called with a socket that wasn't previously
    mounted by a live controller. If this has happened during testing, please first call mount/3
    with your socket and then use socket returned from mount for subsequent LiveView calls.

    """)
  end

  def raise_reply_for_noreply_handler(module, context) do
    raise("""
    #{inspect(module)} unexpectedly replied when handling #{error_context_to_string(context)}.

    You can only reply when handling events (with {:reply, payload, socket} or by calling reply/2).

    """)
  end

  defp error_context_to_string({:action, action}), do: "action #{action}"
  defp error_context_to_string({:event, event}), do: "event #{event}"
  defp error_context_to_string({:message, key}), do: "message with key #{key}"
end
