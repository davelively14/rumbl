defmodule Rumbl.InfoSys do
  # Will list all of the backends that we support
  @backends [Rumbl.InfoSys.Wolfram]

  defmodule Result do
    defstruct score: 0, text: nil, url: nil, backend: nil
  end

  # Proxy for a particular backend. All backends will be InfoSys workers,
  # which are :simple_one_for_one.
  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  # Maps over all backends
  def compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends

    backends
    |> Enum.map(&spawn_query(&1, query, limit))

    # Awaits results from all spawned backends...don't like it this way. Delays
    # getting data to the UI.
    |> await_results(opts)
    |> Enum.sort(&(&1.score >= &2.score))
    |> Enum.take(limit)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(Rumbl.InfoSys.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  # Initial await_results
  defp await_results(children, _opts) do
    # Enters accumulation
    await_result(children, [], :infinity)
  end
  # Recurses over spawned backends
  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      {:results, ^query_ref, results} ->
        # Tries to receive next valid result for query, processes it, demonitors
        # it. Flush guarantees the :DOWN message will be removed from our inbox
        # in case it was delivered before we dropped the monitor.
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      # Matches to monitor_ref (because that's where :DOWN messages occur), not
      # to query_ref.
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
    end
  end
  # Breaks recursion
  defp await_result([], acc, _) do
    acc
  end
end
