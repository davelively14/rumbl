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
  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000
    # Once timeout expires, this will send :timedout to itself. :timedout is
    # handled in our await_results/3 function below.
    timer = Process.send_after(self(), :timedout, timeout)
    results = await_result(children, [], :infinity)
    # Calls cleanup function to clear out the timer once results are received
    cleanup(timer)
    results
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
      :timedout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end
  # Breaks recursion
  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)

    # Flush :timedout message from our inbox if it was sent
    receive do
      :timedout -> :ok
    after
      0 -> :ok
    end
  end
end
