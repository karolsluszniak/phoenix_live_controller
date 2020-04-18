defmodule Phoenix.LiveControllerTest do
  use ExUnit.Case
  import Phoenix.LiveView

  test "mounting actions" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{}, socket)
    assert socket.assigns.items == ["first", :second]
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

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{}, socket)
    refute Phoenix.LiveController.mounted?(socket)

    # first call to handle_params should mark socket as mounted without invoking action handler
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "x"}, "", socket)
    assert Phoenix.LiveController.mounted?(socket)
    assert socket.assigns.items == ["first", :second]

    # further calls should work as expected
    assert {:noreply, socket} = SampleLive.handle_params(%{"first_item" => "x"}, "", socket)
    assert Phoenix.LiveController.mounted?(socket)
    assert socket.assigns.items == ["x", :second]
  end

  test "handling events" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])

    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert socket.assigns.items == [:old, "new"]
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
    assert socket.assigns.user == "me"
  end

  test "applying session redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{"user" => "badguy"}, socket)
    assert socket.redirected
    refute Map.has_key?(socket.assigns, :user)
  end

  test "pipelines: before action mount" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{}, %{}, socket)
    assert Map.has_key?(socket.assigns, :before_action_handler_called)
  end

  test "pipelines: before action mount redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"redirect" => "1"}, %{}, socket)
    assert socket.redirected
    refute Map.has_key?(socket.assigns, :items)
    refute Map.has_key?(socket.assigns, :before_action_handler_called)
  end

  test "pipelines: overriding action mount" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{}, socket)
    assert socket.assigns.action_handler_override
  end

  test "pipelines: before event handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])

    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert Map.has_key?(socket.assigns, :before_event_handler_called)
  end

  test "pipelines: before event handler redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])

    assert {:noreply, socket} =
             SampleLive.handle_event("create", %{"new_item" => "new", "redirect" => "1"}, socket)

    assert socket.redirected
    assert socket.assigns.items == [:old]
    refute Map.has_key?(socket.assigns, :before_event_handler_called)
  end

  test "pipelines: overriding event handler" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(items: [:old])

    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new"}, socket)
    assert socket.assigns.event_handler_override
  end

  test "pipelines: before message handler" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns[:called]
    assert Map.has_key?(socket.assigns, :before_message_handler_called)
  end

  test "pipelines: before message handler redirected" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:noreply, socket} = SampleLive.handle_info({:x, :redirect}, socket)
    assert socket.redirected
    refute socket.assigns[:called]
    refute Map.has_key?(socket.assigns, :before_message_handler_called)
  end

  test "pipelines: overriding message handler" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns.message_handler_override
  end

  test "pipelines: unless_redirected/2" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(:called, false)

    redirected_socket =
      socket
      |> push_redirect(to: "/")

    func = fn socket ->
      assign(socket, :called, true)
    end

    assert Phoenix.LiveController.unless_redirected(socket, func).assigns.called
    refute Phoenix.LiveController.unless_redirected(redirected_socket, func).assigns.called
  end

  test "handling messages" do
    socket = %Phoenix.LiveView.Socket{}

    assert {:noreply, socket} = SampleLive.handle_info(:x, socket)
    assert socket.assigns.called == true
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
    Message 1 cannot be handled by message handler and SampleLive
    doesn't implement handle_info/3 that would handle it instead.

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
end
