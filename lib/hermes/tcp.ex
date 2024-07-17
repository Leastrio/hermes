defmodule Hermes.Tcp do
  use Hermes.Protocol

  defstruct []

  @impl true
  def parse(_binary) do
    nil
  end

  @impl true
  def build(_struct) do
    nil
  end

  @impl true
  def process_protocol(_struct, _tuple) do
    nil
  end
end
