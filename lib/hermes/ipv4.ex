defmodule Hermes.Ipv4 do
  use Hermes.Protocol

  defstruct [
    :version,
    :ihl,
    :dscp,
    :ecn,
    :length,
    :id,
    :flags,
    :frag_offset,
    :ttl,
    :protocol,
    :header_checksum,
    :src_addr,
    :dest_addr,
    :opts,
    :data
  ]

  @impl true
  def parse(
        <<version::4, ihl::4, dscp::6, ecn::2, length::16, id::16, flags::3, frag_offset::13,
          ttl::8, protocol::8, header_checksum::16, src_addr::32, dest_addr::32,
          options::size((ihl - 5) * 32), data::binary>>
      ) do
    data = parse_data(data, protocol)
    %__MODULE__{
      version: version,
      ihl: ihl,
      dscp: dscp,
      ecn: ecn,
      length: length,
      id: id,
      flags: flags,
      frag_offset: frag_offset,
      ttl: ttl,
      protocol: protocol,
      header_checksum: header_checksum,
      src_addr: src_addr,
      dest_addr: dest_addr,
      opts: options,
      data: data
    }
  end

  @impl true
  def build(%__MODULE__{version: version, ihl: ihl, dscp: dscp, ecn: ecn, length: length, id: id, flags: flags, frag_offset: frag_offset,
                        ttl: ttl, protocol: protocol, header_checksum: header_checksum, src_addr: src_addr, dest_addr: dest_addr,
                        opts: opts, data: data}
      ) do
    data = build_inner(data)
    <<version::4, ihl::4, dscp::6, ecn::2, length::16, id::16, flags::3, frag_offset::13,
          ttl::8, protocol::8, header_checksum::16, src_addr::32, dest_addr::32,
          opts::size((ihl - 5) * 32), data::binary>>
  end

  @impl true
  def process_protocol(%__MODULE__{data: data} = packet, state) do
    checksum = %__MODULE__{packet | data: <<>>} |> build() |> calc_checksum()
    if checksum == 0 do
      payload = case data do
        %Hermes.Icmp{} -> Hermes.Icmp.process_protocol(data, state)
        _ -> nil
      end

      prepare_packet(packet, payload, state)
    end
  end

  defp prepare_packet(_packet, nil, _state), do: nil
  defp prepare_packet(%__MODULE__{src_addr: src} = packet, payload, {_mac, ip}) do
    %__MODULE__{packet | data: payload, dest_addr: src, src_addr: ip}
  end

  defp parse_data(data, protocol) do
    case protocol do
      1 -> Hermes.Icmp.parse(data)
      6 -> Hermes.Tcp.parse(data)
      _ -> data
    end
  end
end
