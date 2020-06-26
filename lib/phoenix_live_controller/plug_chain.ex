defmodule Phoenix.LiveController.PlugChain do
  @moduledoc false

  def build_before(module) do
    plugs = Module.get_attribute(module, :plugs)

    quote do
      defp __live_controller_before__(socket, type, name, payload) do
        unquote(build_plug_calls(plugs))
      end
    end
  end

  defp build_plug_calls([]) do
    quote(do: socket)
  end

  defp build_plug_calls(plugs) do
    plug_calls =
      plugs
      |> Enum.map(&build_plug_call/1)
      |> chain_calls()

    quote do
      unquote(expose_plug_global_vars())
      unquote(plug_calls)
    end
  end

  defp build_plug_call({caller, args, conditions, target_mod, target_fun}) do
    call =
      if args do
        args = Enum.map(args, &prepare_plug_expression(&1, caller))
        quote(do: unquote(target_fun)(unquote_splicing(args)))
      else
        args = quote(do: [socket])

        if target_mod,
          do: quote(do: unquote(target_mod).unquote(target_fun)(unquote_splicing(args))),
          else: quote(do: unquote(target_fun)(unquote_splicing(args)))
      end

    quote do
      chain(socket, fn socket ->
        unquote(expose_plug_local_vars())

        if unquote(prepare_plug_expression(conditions, caller)) do
          unquote(call)
        else
          socket
        end
      end)
    end
  end

  defp chain_calls(calls) do
    calls
    |> Enum.reverse()
    |> Enum.reduce(fn
      {name, [], [_socket | rem_args]}, last_socket ->
        {name, [], [last_socket | rem_args]}
    end)
  end

  defp expose_plug_local_vars do
    quote do
      var!(socket) = socket

      var!(socket)
    end
  end

  defp expose_plug_global_vars do
    quote do
      var!(name) = name
      var!(action) = if type == :action, do: name
      var!(event) = if type == :event, do: name
      var!(params) = if type in [:action, :event], do: payload
      var!(message) = if type == :message, do: payload

      var!(name)
      var!(params)
      var!(message)
      var!(action)
      var!(event)
    end
  end

  defp prepare_plug_expression(expr, caller) do
    expr
    |> remove_vars_context([:params, :payload, :action, :event, :message, :socket])
    |> Macro.expand(caller)
  end

  defp remove_vars_context(ast, vars) do
    ast
    |> Macro.prewalk(nil, fn
      node = {var, meta, _}, nil ->
        if var in vars,
          do: {{var, Keyword.delete(meta, :counter), nil}, nil},
          else: {node, nil}

      node, nil ->
        {node, nil}
    end)
    |> elem(0)
  end
end
