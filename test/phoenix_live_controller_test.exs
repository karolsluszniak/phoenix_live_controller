defmodule Phoenix.LiveControllerTest do
  use ExUnit.Case
  import Phoenix.LiveView

  test "mounting actions" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "first"}, "", socket)
    assert socket.assigns.items == ["first", :second]
    assert socket.assigns.global_plug_called
    assert %{other_global_plug_called: :arg} = socket.assigns
  end

  test "mounting actions without plugs" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SimpleLive.mount(%{}, %{}, socket)
    assert {:noreply, _socket} = SampleLive.handle_params(%{}, "", socket)
  end

  test "mounting actions with options" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index_with_opts)

    assert {:ok, socket, opts} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "first"}, "", socket)
    assert opts[:temporary_assigns] == [items: []]
    refute Map.has_key?(socket.assigns, :other_global_plug_called)
  end

  test "mounting undefined actions" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :badactionnn)

    expected_error = """
    SampleLive doesn't implement action handler for :badactionnn action.

    Make sure that badactionnn function is defined and annotated as action handler:

        @action_handler true
        def badactionnn(socket, params) do
          # ...
        end

    """

    assert_raise(RuntimeError, expected_error, fn ->
      SampleLive.mount(%{}, %{}, socket)
    end)
  end

  test "mounting without action" do
    socket = %Phoenix.LiveView.Socket{}

    expected_error = """
    SampleLive called without action.

    Make sure to mount it via route that specifies action, e.g. for :index action:

        live "/some_url", SampleLive, :index

    """

    assert_raise(RuntimeError, expected_error, fn ->
      SampleLive.mount(%{}, %{}, socket)
    end)
  end

  test "patching params" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    refute Phoenix.LiveController.mounted?(socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "first"}, "", socket)
    assert Phoenix.LiveController.mounted?(socket)
    assert socket.assigns.items == ["first", :second]

    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "x"}, "", socket)
    assert Phoenix.LiveController.mounted?(socket)
    assert socket.assigns.items == ["x", :second]

    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "y"}, "", socket)
    assert Phoenix.LiveController.mounted?(socket)
    assert socket.assigns.items == ["y", :second]
  end

  test "patching params with non-mounted socket" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    expected_error = """
    SampleLive unexpectedly received socket without controller state when handling
    action index.

    This means that one of LiveView callbacks was called with a socket that wasn't previously
    mounted by a live controller. If this has happened during testing, please first call mount/3
    with your socket and then use socket returned from mount for subsequent LiveView calls.

    """

    assert_raise RuntimeError, expected_error, fn ->
      SampleLive.handle_params(%{}, "", socket)
    end
  end

  test "patching params with a reply" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index_reply)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)

    expected_error = """
    SampleLive unexpectedly replied when handling action index_reply.

    You can only reply when handling events (with {:reply, payload, socket} or by calling reply/2).

    """

    assert_raise RuntimeError, expected_error, fn ->
      SampleLive.handle_params(%{}, "", socket)
    end
  end

  test "handling events" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert socket.assigns.items == [:old, "new"]
  end

  test "handling events with reply" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)

    assert {:reply, :some_reply, socket} =
             SampleLive.handle_event(
               "create_reply",
               %{"new_item" => "new"},
               socket
             )

    assert socket.assigns.items == [:old, "new"]
    assert socket.controller.reply_payload == nil
  end

  test "handling events with tuple reply in plug" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)

    assert {:reply, :other_reply, socket} =
             SampleLive.handle_event(
               "create_reply_plug",
               %{"new_item" => "new"},
               socket
             )

    assert socket.assigns.items == [:old]
    assert socket.controller.reply_payload == nil
  end

  test "handling events with non-mounted socket" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    expected_error = """
    SampleLive unexpectedly received socket without controller state when handling
    event create.

    This means that one of LiveView callbacks was called with a socket that wasn't previously
    mounted by a live controller. If this has happened during testing, please first call mount/3
    with your socket and then use socket returned from mount for subsequent LiveView calls.

    """

    assert_raise RuntimeError, expected_error, fn ->
      SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    end
  end

  test "handling events with bad response" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{"user" => "me"}, socket)

    expected_error = """
    SampleLive returned unexpected value when handling event create_bad_resp:

    :bad_resp

    You can only return socket, optionally wrapped in {:noreply, socket} tuple
    or, when handling events, in {:reply, payload, socket} tuple.

    """

    assert_raise RuntimeError, expected_error, fn ->
      SampleLive.handle_event("create_bad_resp", %{}, socket)
    end
  end

  test "handling undefined events" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])

    expected_error = """
    SampleLive doesn't implement event handler for "badeventtt" event.

    Make sure that badeventtt function is defined and annotated as event handler:

        @event_handler true
        def badeventtt(socket, params) do
          # ...
        end

    """

    assert_raise(RuntimeError, expected_error, fn ->
      SampleLive.handle_event("badeventtt", %{}, socket)
    end)
  end

  test "applying session" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{"user" => "me"}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{}, "", socket)
    assert socket.assigns.user == "me"
  end

  test "applying session redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{"user" => "badguy"}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{}, "", socket)
    assert socket.redirected
    refute Map.has_key?(socket.assigns, :user)
  end

  test "pipelines: before action mount" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{}, "", socket)
    assert Map.has_key?(socket.assigns, :before_action_handler_called)
    assert Map.has_key?(socket.assigns, :before_action_handler_called_two)

    assert socket.assigns.plug_history == [
             :before_action_handler_called,
             :before_action_handler_called_two
           ]

    assert socket.assigns.global_plug_called == {:index, %{}}
  end

  test "pipelines: before action mount redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{"redirect" => "1"}, "", socket)
    assert socket.redirected
    refute Map.has_key?(socket.assigns, :items)
    refute Map.has_key?(socket.assigns, :before_action_handler_called)
  end

  test "pipelines: overriding action mount" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "first"}, "", socket)
    assert socket.assigns.action_handler_override
  end

  test "pipelines: before event handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert Map.has_key?(socket.assigns, :before_event_handler_called)
    assert socket.assigns.global_plug_called == {:create, %{"new_item" => "new"}}
  end

  test "pipelines: before event handler redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)

    assert {:noreply, socket} =
             SampleLive.handle_event("create", %{"new_item" => "new", "redirect" => "1"}, socket)

    assert socket.redirected
    assert socket.assigns.items == [:old]
    assert Map.has_key?(socket.assigns, :other_global_plug_called)
    refute Map.has_key?(socket.assigns, :before_event_handler_called)
  end

  test "pipelines: overriding event handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert socket.assigns.event_handler_override
  end

  test "pipelines: before message handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns[:called]
    assert Map.has_key?(socket.assigns, :before_message_handler_called)
    assert {:x, :x} == socket.assigns.global_plug_called
    refute Map.has_key?(socket.assigns, :other_global_plug_called)
  end

  test "pipelines: before message handler redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_info({:x, :redirect}, socket)
    assert socket.redirected
    refute socket.assigns[:called]
    refute Map.has_key?(socket.assigns, :before_message_handler_called)
  end

  test "pipelines: overriding message handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns.message_handler_override
  end

  test "pipelines: chain/2" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(:called, false)
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)

    redirected_socket =
      socket
      |> push_redirect(to: "/")

    func = fn socket ->
      assign(socket, :called, true)
    end

    assert Phoenix.LiveController.chain(socket, func).assigns.called
    refute Phoenix.LiveController.chain(redirected_socket, func).assigns.called
  end

  test "handling messages" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns.called == true
  end

  test "handling messages with non-mounted socket" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    expected_error = """
    SampleLive unexpectedly received socket without controller state when handling
    message with key x.

    This means that one of LiveView callbacks was called with a socket that wasn't previously
    mounted by a live controller. If this has happened during testing, please first call mount/3
    with your socket and then use socket returned from mount for subsequent LiveView calls.

    """

    assert_raise RuntimeError, expected_error, fn ->
      SampleLive.handle_info(:x, socket)
    end
  end

  test "handling undefined messages" do
    socket = %Phoenix.LiveView.Socket{}

    expected_error = """
    SampleLive doesn't implement message handler for :badmsggg message.

    Make sure that badmsggg function is defined and annotated as message handler:

        @message_handler true
        def badmsggg(socket, message) do
          # ...
        end

    """

    assert_raise(RuntimeError, expected_error, fn ->
      SampleLive.handle_info(:badmsggg, socket)
    end)
  end

  test "handling unsupported messages" do
    socket = %Phoenix.LiveView.Socket{}

    expected_error = """
    Message 1 cannot be handled by message handler and
    SampleLive doesn't implement handle_info/3 that would handle it instead.

    Make sure that appropriate handle_info/3 function matching this message is defined:

        def handle_info(message, socket) do
          # ...
        end

    """

    assert_raise(RuntimeError, expected_error, fn ->
      SampleLive.handle_info(1, socket)
    end)
  end

  test "rendering actions" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index, other: :x)

    assert {:rendered, "index.html", %{live_action: :index, other: :x}} =
             SampleLive.render(socket.assigns)
  end

  test "get_current_url/1" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{}, socket)
    assert Phoenix.LiveController.get_current_url(socket) == nil

    assert {:noreply, socket} = SampleLive.handle_params(%{}, "http://x.y/z?a=1", socket)
    assert Phoenix.LiveController.get_current_url(socket) == "http://x.y/z?a=1"
  end

  test "get_session/1" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{"x" => "y"}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{}, "", socket)

    assert Phoenix.LiveController.get_session(socket) == %{"x" => "y"}
  end

  test "get_session/2" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{"x" => "y"}, socket)
    assert {:noreply, socket} = SampleLive.handle_params(%{}, "", socket)

    assert Phoenix.LiveController.get_session(socket, "x") == "y"
    assert Phoenix.LiveController.get_session(socket, :x) == "y"
    assert Phoenix.LiveController.get_session(socket, "a") == nil
    assert Phoenix.LiveController.get_session(socket, :a) == nil
  end
end
