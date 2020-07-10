defmodule Phoenix.LiveController.ControllerState do
  @moduledoc """
  Embeds extra state in socket to facilitate Phoenix live controllers.
  """

  @type t() :: %__MODULE__{
          mounted?: boolean(),
          reply_payload: term(),
          session: map(),
          url: String.t()
        }

  @derive {Inspect, except: [:session, :url]}

  @enforce_keys [:mounted?, :session]

  defstruct mounted?: false,
            reply_payload: nil,
            session: %{},
            url: nil
end
