defmodule Mongo.Auth.Plain do
  @moduledoc false

  import Mongo.Protocol.Utils

  def auth({username, password}, s) do
    encoded_auth = Base.encode64("\x00#{username}\x00#{password}")
    result = command(-1, [saslStart: 1, mechanism: "PLAIN", payload: encoded_auth, autoAuthorize: 1], s)

    case result do
      {:ok, _res} -> :ok
      error -> error
    end
  end
end
