defmodule Hermes.Arp do
  use Hermes.Protocol

  defstruct [:htype, :ptype, :hlen, :plen, :oper, :sha, :spa, :tha, :tpa]

  def parse(
        <<htype::16, ptype::16, hlen::8, plen::8, oper::16, sha::unit(8)-size(hlen),
          spa::unit(8)-size(plen), tha::unit(8)-size(hlen), tpa::unit(8)-size(plen)>>
      ) do
    %__MODULE__{
      htype: htype,
      ptype: ptype,
      hlen: hlen,
      plen: plen,
      oper: oper,
      sha: sha,
      spa: spa,
      tha: tha,
      tpa: tpa
    }
  end

  def build(%__MODULE__{
        htype: htype,
        ptype: ptype,
        hlen: hlen,
        plen: plen,
        oper: oper,
        sha: sha,
        spa: spa,
        tha: tha,
        tpa: tpa
      }) do
    <<htype::16, ptype::16, hlen::8, plen::8, oper::16, sha::48, spa::32, tha::48, tpa::32>>
  end

  def process_protocol(
        %__MODULE__{sha: sha, spa: spa},
        {mac, ip}
      ) do
    %__MODULE__{
      htype: 1,
      ptype: 2048,
      hlen: 6,
      plen: 4,
      oper: 2,
      sha: mac,
      spa: ip,
      tha: sha,
      tpa: spa
    }
  end
end
