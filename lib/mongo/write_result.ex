defmodule Mongo.WriteResult do
  # On 2.4 num_modified will always be nil

  defstruct [
    :type,
    :num_inserted,
    :num_matched,
    :num_modified,
    :num_removed,
    :upserted_id
  ]
end
