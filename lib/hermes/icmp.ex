defmodule Hermes.Icmp do
  use Hermes.Protocol

  defstruct [:type, :code, :checksum, :extended, :payload]

  @impl true
  def parse(<<type::8, code::8, checksum::16, extended::32, payload::binary>>) do
    %__MODULE__{type: type, code: code, checksum: checksum, extended: extended, payload: payload}
  end  

  @impl true
  def build(%__MODULE__{type: type, code: code, checksum: checksum, extended: extended, payload: payload}) do
    <<type::8, code::8, checksum::16, extended::32, payload::binary>>
  end

  @impl true
  def process_protocol(%__MODULE__{extended: extended, payload: payload} = packet, _state) do
    checksum = packet |> build() |> calc_checksum()
    if checksum == 0 do
      reply = %__MODULE__{type: 0, code: 0, checksum: 0, extended: extended, payload: payload}
      checksum = reply |> build() |> calc_checksum()
      %__MODULE__{reply | checksum: checksum}
    end
  end

end
