defmodule SomeLiveBench do
  import Phoenix.LiveView

  def run do
    run_file(:inline, SampleInlineLive)
    run_file(:plug_atom, SamplePlugAtomLive)
    run_file(:plug_func, SamplePlugFuncLive)
  end

  defp run_file(name, mod) do
    socket =
      %Phoenix.LiveView.Socket{}
      |> assign(live_action: :index)

    time("#{name} compile", fn ->
      Code.compile_file("priv/bench/sample_#{name}_live.ex")
    end)

    time("#{name} run", fn ->
      for _ <- 1..5000, do: mod.mount(%{}, %{}, socket)
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
