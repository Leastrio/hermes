defmodule Hermes.TapServer do
  use GenServer
  require Logger
  alias Hermes.Native
  alias Hermes.Ethernet
  alias Hermes.Arp
  alias Hermes.Utils

  @route "10.0.0.0/24"
  @ip "10.0.0.1"
  
  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:ok, resource, name} = Native.tuntap_init()

    Utils.run_cmd("ip", ["link", "set", to_string(name), "up"])
    Utils.run_cmd("ip", ["route", "add", "dev", to_string(name), @route])
    Utils.run_cmd("ip", ["address", "add", "dev", to_string(name), "local", @ip])
    Logger.info("Started device at #{to_string(name)}")

    info = get_if_info(name)
    <<mac::48>> = :binary.list_to_bin(Keyword.get(info, :hwaddr))
    ip = ip_to_int(Keyword.get(info, :addr))

    {:ok, {resource, mac, ip}}
  end

  @impl true
  def handle_info(:read_ready, {resource, _mac, _ip} = state) do
    Logger.debug("Recv read ready")
    data = Native.read_tap(resource)
    Task.Supervisor.start_child(Hermes.TaskSupervisor, fn ->
      frame = Ethernet.parse(data)
      handle_frame(frame, state)
    end)
    {:noreply, state}
  end

  def handle_frame(%Ethernet{payload: payload} = frame, {_resource, _mac, ip} = state) do
    IO.inspect(frame, label: "RX")
    case payload do
      %Arp{tpa: tpa} when tpa == ip -> Arp.handle_packet(frame, payload, state)
      _ -> :ok
    end
  end

  defp get_if_info(name) do
    {:ok, entries} = :inet.getifaddrs()
    Enum.find(entries, fn {if_name, _opts} -> if_name == name end)
    |> elem(1)
  end

  def ip_to_int({a, b, c, d}) do
    <<rest::32>> = <<a::8, b::8, c::8, d::8>>
    rest
  end
end
