defmodule Hermes.TapServer do
  use GenServer
  require Logger
  alias Hermes.Native
  alias Hermes.Ethernet
  alias Hermes.Utils

  @route "10.0.0.1/24"
  @ip <<10::8, 0::8, 0::8, 5::8>>

  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    {:ok, resource, device_name} = Native.tuntap_init()

    Utils.run_cmd("ip", ["link", "set", to_string(device_name), "up"])
    Utils.run_cmd("ip", ["address", "add", @route, "dev", to_string(device_name)])
    Logger.info("Started device at #{to_string(device_name)}")

    {:ok, resource, {:continue, device_name}}
  end

  @impl true
  def handle_continue(device_name, resource) do
    # sleep before fetching the mac because for some reason it changes
    Process.sleep(1000)
    <<mac::48>> = get_mac_addr(device_name)
    <<ip::32>> = @ip

    {:noreply, {resource, mac, ip}}
  end

  @impl true
  def handle_info(:read_ready, {resource, _mac, _ip} = state) do
    Logger.debug("Reading incoming data...")
    data = Native.read_tap(resource)

    Task.Supervisor.start_child(Hermes.TaskSupervisor, fn ->
      data
      |> Ethernet.parse()
      |> Ethernet.process_protocol(state)
    end)

    {:noreply, state}
  end

  defp get_mac_addr(name) do
    {:ok, entries} = :inet.getifaddrs()

    Enum.find(entries, fn {if_name, _opts} -> if_name == name end)
    |> elem(1)
    |> Keyword.get(:hwaddr)
    |> :binary.list_to_bin()
  end
end
