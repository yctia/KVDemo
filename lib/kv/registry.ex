defmodule KV.Registry do
  @moduledoc false
  
  use GenServer

  ## Client API

  @doc """
  Starts the registry with an given name.
  """
  def start_link(name) do
    # 1. Pass the name to GenServer's init
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @doc """
  Looks up the bucket pid for 'name' stored in 'server'
  Returns {:ok, pid} if the bucket exists, :error otherwise.
  """
  def lookup(server, name) do
    # 2. Lookup is now done directly in-ETS, without accessing the server
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end

    # using genserver not ets
    #GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated to the given 'name' in 'server'.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  ## Server API

  def init(table) do
  #def init(:ok) do
    # use genserver not ets
    #names = %{}

    # 3. we have replaced the names map by the ETS table.
    names = :ets.new(table, [:named_table, read_concurrency: true])

    refs = %{}
    {:ok, {names, refs}}
  end

  # use genserver
  #def handle_call({:lookup, name}, _from, {names, _} = state) do
  #  {:reply, Map.fetch(names, name), state}
  #end

  # 4. The previous handle_call callback for lookup was removed

  def handle_cast({:create, name}, {names, refs}) do
    # 5. Read and Write to the ETS table instead of the map
    case lookup(names, name) do
      {:ok, _pid} ->
        {:noreply, {names, refs}}
      :error ->
        {:ok, pid} = KV.Bucket.Supervisor.start_bucket
        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:noreply, {names, refs}}
    end

    # use Genserver
    """
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.Supervisor.start_bucket
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
    """
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    # 6. Detete from ETS table instead of the map
    :ets.delete(names, name)

    # use Genserver
    #names = Map.delete(names, name)

    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state)do
    {:noreply, state}
  end
end