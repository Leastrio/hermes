defmodule Hermes.Ethernet do
  defstruct [:mac_dest, :mac_src, :tag, :ethertype, :payload]

  defmodule Tag do
    defstruct [:tpid, :pcp, :dei, :vid]
  end

  def parse(<<dest::48, src::48, 0x8100::16, pcp::3, dei::1, vid::12, type::16, payload::binary>>) do
    payload = parse_payload(payload, type)
    %__MODULE__{mac_dest: dest, mac_src: src, tag: %Tag{tpid: 0x8100, pcp: pcp, dei: dei, vid: vid}, ethertype: type, payload: payload}
  end

  def parse(<<dest::48, src::48, type::16, payload::binary>>) do
    payload = parse_payload(payload, type)
    %__MODULE__{mac_dest: dest, mac_src: src, ethertype: type, payload: payload}
  end

  defp parse_payload(payload, type) do
    case type do
      0x0806 -> Hermes.Arp.parse(payload)
      _ -> payload
    end
  end

  def build(%__MODULE__{mac_dest: dest, mac_src: src, tag: tag, ethertype: type, payload: payload}) do
    data = case is_map(payload) do
      false -> payload
      true -> apply(payload.__struct__, :build, [payload])
    end
    <<dest::48, src::48>> <> build_tag(tag) <> <<type::16>> <> data
  end

  defp build_tag(nil), do: <<>>
  defp build_tag(%Tag{tpid: tpid, pcp: pcp, dei: dei, vid: vid}), do: <<tpid::16, pcp::3, dei::1, vid::12>>
end
