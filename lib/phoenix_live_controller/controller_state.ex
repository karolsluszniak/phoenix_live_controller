defmodule Phoenix.LiveController.ControllerState do
  @moduledoc """
  Embeds extra state in socket to facilitate Phoenix live controllers.
  """

  @type t() :: %__MODULE__{
          mounted?: boolean(),
          session: map(),
          url: String.t()
        }

  @derive {Inspect, except: [:session, :url]}

  @enforce_keys [:mounted?, :session]

  defstruct mounted?: false,
            session: %{},
            url: nil
end
