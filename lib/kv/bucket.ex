defmodule KV.Bucket do
  @doc """
  Starts a new bucket.
  """
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value form bucket by key
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the value for the given key in the bucket.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Deletes key from bucket.
  """

  def delete(bucket, key) do
    #Process.sleep(1000) # puts client to sleep
    Agent.get_and_update(bucket, fn dict ->
     # Process.sleep(1000) # puts server to sleep
      Map.pop(dict, key) end)
  end
end