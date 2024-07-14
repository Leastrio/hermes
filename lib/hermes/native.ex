defmodule Hermes.Native do
  @on_load :load_nifs

  def load_nifs() do
    :erlang.load_nif("./native/tuntap", 0)
  end

  def tuntap_init() do
    :erlang.nif_error(:not_implemented)
  end

  def read_tap(_ref) do
    :erlang.nif_error(:not_implemented)
  end

  def write_tap(_ref, _buf) do
    :erlang.nif_error(:not_implemented)
  end
end
