defmodule Hermes.Ethernet do
  use Hermes.Protocol
  require Logger

  defstruct [:mac_dest, :mac_src, :tag, :ethertype, :payload]

  defmodule Tag do
    defstruct [:tpid, :pcp, :dei, :vid]
  end

  @impl true
  def parse(<<dest::48, src::48, 0x8100::16, pcp::3, dei::1, vid::12, type::16, payload::binary>>) do
    payload = parse_payload(payload, type)

    %__MODULE__{
      mac_dest: dest,
      mac_src: src,
      tag: %Tag{tpid: 0x8100, pcp: pcp, dei: dei, vid: vid},
      ethertype: type,
      payload: payload
    }
  end

  @impl true
  def parse(<<dest::48, src::48, type::16, payload::binary>>) do
    payload = parse_payload(payload, type)
    %__MODULE__{mac_dest: dest, mac_src: src, ethertype: type, payload: payload}
  end

  @impl true
  def build(%__MODULE__{mac_dest: dest, mac_src: src, tag: tag, ethertype: type, payload: payload}) do
    data = build_inner(payload)
    <<dest::48, src::48>> <> build_tag(tag) <> <<type::16>> <> data
  end

  @impl true
  def process_protocol(%__MODULE__{mac_src: src, tag: tag, ethertype: type, payload: payload} = frame, {resource, mac, ip}) do
    IO.inspect(frame, label: "RX")

    inner = case payload do
      %Hermes.Arp{tpa: tpa} when tpa == ip -> Hermes.Arp.process_protocol(payload, {mac, ip})
      %Hermes.Ipv4{} -> Hermes.Ipv4.process_protocol(payload, {mac, ip})
      _ -> nil
    end

    if inner != nil do
      resp = %__MODULE__{mac_dest: src, mac_src: mac, tag: tag, ethertype: type, payload: inner}
      |> build()

      Hermes.Native.write_tap(resource, resp)
      Logger.info("Sent reply!")
    end
  end

  defp parse_payload(payload, type) do
    case type do
      0x0806 -> Hermes.Arp.parse(payload)
      0x0800 -> Hermes.Ipv4.parse(payload)
      _ -> payload
    end
  end

  defp build_tag(nil), do: <<>>

  defp build_tag(%Tag{tpid: tpid, pcp: pcp, dei: dei, vid: vid}),
    do: <<tpid::16, pcp::3, dei::1, vid::12>>

end
