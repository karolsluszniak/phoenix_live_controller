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

    assert_raise(RuntimeError, "SampleLive doesn't implement action mount for :badactionnn", fn ->
      SampleLive.mount(%{}, %{}, socket)
    end)
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

    assert_raise(RuntimeError, "SampleLive doesn't implement event handler for \"badeventtt\"", fn ->
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
    assert Map.has_key?(socket.assigns, :before_action_mount_called)
  end

  test "pipelines: before action mount redirected" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"redirect" => "1"}, %{}, socket)
    assert socket.redirected
    refute Map.has_key?(socket.assigns, :items)
    refute Map.has_key?(socket.assigns, :before_action_mount_called)
  end

  test "pipelines: overriding action mount" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    assert {:ok, socket} = SampleLive.mount(%{"first_item" => "first"}, %{}, socket)
    assert socket.assigns.action_mount_override
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

    assert {:noreply, socket} = SampleLive.handle_event("create", %{"new_item" => "new", "redirect" => "1"}, socket)
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

  test "rendering actions" do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index, other: :x)

    assert {:rendered, "index.html", %{live_action: :index, other: :x}} = SampleLive.render(socket.assigns)
  end
end
