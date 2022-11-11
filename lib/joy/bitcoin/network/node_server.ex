defmodule Joy.Bitcoin.Network.NodeServer do
  @moduledoc """
  This module connects to a Bitcoin node via TCP and handles incoming and
  outgoing messages. For more information see:

  https://en.bitcoin.it/wiki/Network
  https://en.bitcoin.it/wiki/Protocol_documentation

  https://developer.bitcoin.org/devguide/p2p_network.html
  https://developer.bitcoin.org/reference/p2p_networking.html

  Heavily inspired by http://www.petecorey.com/blog/tags/#bitcoin
  """
  use Connection

  @max_retries 3
  @timeout 30_000
  @ping_time 15_000

  # alias Joy.Bitcoin.Network
  alias Hexdump
  alias Joy.Bitcoin.Network.IP

  alias Joy.Bitcoin.Network.Protocol.{
    Addr,
    Block,
    GetData,
    Inv,
    Message,
    Ping,
    Pong,
    Tx,
    Version
  }

  def start_link({ip, port}) do
    Connection.start_link(__MODULE__, %{
      ip: ip,
      port: port,
      rest: "",
      retries: 0
    })
  end

  def init(state) do
    {:connect, nil, state}
  end

  def connect(_info, state = %{retries: @max_retries}) do
    {:stop, :normal, state}
  end

  def connect(_info, state) do
    options = [:binary, active: true]

    version = %Version{
      version: 70_016,
      services: 0,
      user_agent: "/Satoshi:23.0.0/",
      from_ip: <<>>,
      from_port: 0,
      from_services: 0,
      timestamp: :os.system_time(:seconds),
      recv_ip: state.ip,
      recv_port: state.port,
      recv_services: 1,
      nonce: :binary.decode_unsigned(:crypto.strong_rand_bytes(8)),
      start_height: 1
    }

    message = Message.serialize("version", version)

    with {:ok, socket} <-
           :gen_tcp.connect(
             IP.to_tuple(state.ip),
             state.port,
             options,
             @timeout
           ),
         :ok <- send_message(message, socket) do
      {:ok, Map.put_new(state, :socket, socket)}
    else
      _ -> {:backoff, 1000, Map.put(state, :retries, state.retries + 1)}
    end
  end

  def disconnect(reason, state) do
    :ok = :gen_tcp.close(state.socket)

    log("Connection closed: " <> Atom.to_string(reason))

    log(
      "Connection retry " <>
        Integer.to_string(state.retries + 1) <>
        "/" <> Integer.to_string(@max_retries)
    )

    {:backoff, 1000, Map.put(state, :retries, state.retries + 1)}
  end

  def handle_info({:tcp, _port, data}, state) do
    state = refresh_timeout(state)
    {messages, rest} = chunk(state.rest <> data)

    case handle_messages(messages, state) do
      {:error, reason, state} -> {:disconnect, reason, %{state | rest: rest}}
      state -> {:noreply, %{state | rest: rest}}
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    {:disconnect, :tcp_closed, state}
  end

  def handle_info(:timeout, state) do
    {:disconnect, :timeout, state}
  end

  def handle_info(:send_ping, state) do
    with :ok <-
           Message.serialize("ping", %Ping{
             nonce: :crypto.strong_rand_bytes(8)
           })
           |> send_message(state.socket) do
      [
        :bright,
        "Sending ",
        :green,
        "ping"
      ]
      |> log()

      {:noreply, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp handle_messages(messages, state) do
    messages
    |> Enum.filter(&Message.verify_checksum/1)
    |> Enum.reduce_while(state, fn message, state ->
      log("Received Message: " <> message.command)

      case handle_payload(message.parsed_payload, state) do
        {:error, reason, state} -> {:halt, {:error, reason, state}}
        {:ok, state} -> {:cont, state}
      end
    end)
  end

  defp handle_payload(%Version{}, state) do
    # log(v.version)
    # log(Integer.to_string(v.services, 2))

    with :ok <- Message.serialize("verack") |> send_message(state.socket),
         :ok <- Message.serialize("getaddr") |> send_message(state.socket),
         :ok <-
           Message.serialize("ping", %Ping{
             nonce: :crypto.strong_rand_bytes(8)
           })
           |> send_message(state.socket) do
      [
        :bright,
        "Received ",
        :green,
        "verack ",
        :reset,
        :bright,
        "- sending ",
        :green,
        "getaddr"
      ]
      |> log()

      {:ok, state}
    else
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp handle_payload(%Ping{nonce: nonce}, state) do
    with :ok <-
           Message.serialize("pong", %Pong{nonce: nonce})
           |> send_message(state.socket) do
      [
        :bright,
        "Received ",
        :green,
        "ping ",
        :reset,
        :bright,
        "- sending ",
        :green,
        "pong"
      ]
      |> log()

      {:ok, state}
    else
      {:error, reason} ->
        {:error, reason, state}
    end
  end

  defp handle_payload(%Pong{}, state) do
    Process.send_after(self(), :send_ping, @ping_time)
    {:ok, state}
  end

  defp handle_payload(%Addr{addr_list: addr_list}, state) do
    log([
      :reset,
      "Received ",
      :bright,
      :green,
      "#{length(addr_list)}",
      :reset,
      " peers."
    ])

    # _ =
    # addr_list
    # |> Enum.sort_by(& &1.time, &>=/2)
    # |> Enum.map(&Network.connect_to_node/1)

    {:ok, state}
  end

  defp handle_payload(inv = %Inv{}, state) do
    log("Received Inv - sending GetData.")

    Message.serialize("getdata", %GetData{
      count: inv.count,
      inventory: inv.inventory
    })
    |> send_message(state.socket)

    {:ok, state}
  end

  defp handle_payload(_tx = %Tx{}, state) do
    log("Received Tx")
    # IO.inspect(tx)
    {:ok, state}
  end

  defp handle_payload(_block = %Block{}, state) do
    log("Received Block")
    # IO.inspect(block)
    {:ok, state}
  end

  defp handle_payload(_payload, state) do
    # log("Received other payload:")

    # Hexdump.to_string(payload)
    # |> IO.puts()

    {:ok, state}
  end

  defp chunk(binary, messages \\ []) do
    case Message.parse(binary) do
      {:ok, message, rest} ->
        chunk(rest, messages ++ [message])

      nil ->
        {messages, binary}
    end
  end

  defp refresh_timeout(state = %{timer: timer}) do
    Process.cancel_timer(timer)
    timer = Process.send_after(self(), :timeout, @timeout)
    Map.put(state, :timer, timer)
  end

  defp refresh_timeout(state) do
    timer = Process.send_after(self(), :timeout, @timeout)
    Map.put_new(state, :timer, timer)
  end

  defp log(message) do
    [:light_black, "[#{inspect(self())}] ", :reset, message]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  defp send_message(message, socket) do
    :gen_tcp.send(socket, message)
  end
end
