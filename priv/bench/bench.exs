defmodule SomeLiveBench do
  import Phoenix.LiveView

  def run do
    run_file(:inline, SampleInlineLive)
    run_file(:plug_atom, SamplePlugAtomLive)
    run_file(:plug_func, SamplePlugFuncLive)
  end

  defp run_file(name, mod) do
    time("#{name} compile", fn ->
      Code.compile_file("priv/bench/sample_#{name}_live.ex")
    end)

    time("#{name} run", fn ->
      for _ <- 1..5000 do
        socket =
          %Phoenix.LiveView.Socket{}
          |> assign(live_action: :index)

        mod.mount(%{}, %{}, socket)

        socket = assign(socket, live_action: :show)
        mod.mount(%{}, %{}, socket)

        socket = assign(socket, live_action: :new)
        {:ok, socket} = mod.mount(%{}, %{}, socket)
        {:noreply, _socket} = mod.handle_event("create", %{}, socket)

        socket = assign(socket, live_action: :edit)
        {:ok, socket} = mod.mount(%{}, %{}, socket)
        {:noreply, _socket} = mod.handle_event("update", %{}, socket)

        {:noreply, _socket} = mod.handle_event("delete", %{}, socket)
      end
    end)
  end

  defp time(label, func) do
    start = DateTime.utc_now |> DateTime.to_unix(:millisecond)
    func.()
    finish = DateTime.utc_now |> DateTime.to_unix(:millisecond)
    diff = (finish - start) / 1000

    IO.puts("#{label}: #{diff}")
  end
end

SomeLiveBench.run()
