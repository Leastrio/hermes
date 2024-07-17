defmodule Hermes.Protocol do
  @callback parse(binary()) :: struct()
  @callback build(struct()) :: binary()
  @callback process_protocol(struct(), {integer(), integer()}) :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Hermes.Protocol
      import Hermes.Utils, only: [build_inner: 1, calc_checksum: 1]
    end
  end
end
