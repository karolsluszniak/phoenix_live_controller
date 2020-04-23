defmodule Phoenix.LiveController.ViewRenderer do
  @moduledoc ~S"""
  Renders live view or component with a view & template named after the live module & action.

  Implementation of the `c:Phoenix.LiveView.render/1` callback may be omitted in which case [a
  collocated template is used as a
  default](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-collocating-templates).
  This basically means that `Phoenix.LiveView` seeks for the template with the same filename as live
  module, with `.ex` extension replaced by `.html.leex`.

  ViewRenderer allows to opt-in for a more controller-style behaviour in which views are invoked to
  render templates from the `lib/my_app_web/templates` directory.

      defmodule MyAppWeb do
        def live_component do
          quote do
            use Phoenix.LiveComponent
            use Phoenix.LiveController.ViewRenderer
            # ...
          end
        end

        def live_controller do
          quote do
            use Phoenix.LiveController
            use Phoenix.LiveController.ViewRenderer
            # ...
          end
        end

        def live_view do
          quote do
            use Phoenix.LiveView
            use Phoenix.LiveController.ViewRenderer
            # ...
          end
        end
      end

  This will inject an implementation of `c:Phoenix.LiveView.render/1` callback that'll ask the view
  module named after specific live module to render HTML template named after the action - the same
  way that Phoenix controllers do when the `Phoenix.Controller.render/2` is called without a
  template name. For example, `MyAppWeb.ArticleLive` mounted with `:index` action will render with
  following call:

      MyAppWeb.ArticleView.render("index.html", assigns)

  Furthermore, for live sub-views or sub-components it'll assume that they're backed by a single
  template and so the injected implementation will ask the view module named after parent live
  module to render HTML template named after the sub-module. For example,
  `MyAppWeb.ArticleLive.FormComponent` will render with following call:

      MyAppWeb.ArticleView.render("form.html", assigns)

  This, together with ViewRenderer being separate from LiveController, allows to consistently hold
  all templates in `lib/my_app_web/templates` directory and to consistently back them with view
  modules in order to accommodate the view logic - even when using live controllers together with
  regular live views and live components.

  Provided renderer is overridable, which means that a custom `c:Phoenix.LiveView.render/1`
  implementation may still be provided if necessary.

  """

  defmacro __using__(_opts) do
    caller_module_string = to_string(__CALLER__.module)

    case Regex.run(~r/(.*Live)\.(\w+)$/, caller_module_string) do
      [_, parent_module_string, submodule] ->
        view_module = live_module_string_to_view_module(parent_module_string)

        action =
          submodule
          |> String.replace(~r/(Live|Component)$/, "")
          |> Macro.underscore()

        quote do
          def render(assigns) do
            unquote(view_module).render("#{unquote(action)}.html", assigns)
          end

          defoverridable render: 1
        end

      _ ->
        view_module = live_module_string_to_view_module(caller_module_string)

        quote do
          def render(assigns = %{live_action: action}) do
            unquote(view_module).render("#{action}.html", assigns)
          end

          defoverridable render: 1
        end
    end
  end

  defp live_module_string_to_view_module(live_module_string) do
    live_module_string
    |> String.replace(~r/Live$/, "")
    |> Kernel.<>("View")
    |> String.to_atom()
  end
end
