defmodule Rumbl.Counter do

  def inc(pid), do: send(pid, :inc)

  def dec(pid), do: send(pid, :dec)

  def val(pid, timeout \\ 5000) do

    # make_ref() creates a reference that is guaranteed to be globally unique.
    # This is then sent to the server in the :val triple tuple in order to id
    # the unique request. This avoids any confusion where my machine may send
    # several requests that might be returned in a different order than sent.
    ref = make_ref()
    send(pid, {:val, self(), ref})
    receive do
      # The ^ operators ensures that instead of reassigning ref, we'll only
      # match tuples that have that exact ref. Explicit request/receive.
      {^ref, val} -> val

    # In this case, after 5000 (5 seconds), this times out
    after timeout -> exit(:timeout)
    end
  end

  # These two functions are the server

  def start_link(initial_val) do
    # spawn_link creates a spawned function and returns a pid of that function,
    # in this case, the listen function.
    {:ok, spawn_link(fn -> listen(initial_val) end)}
  end

  # The state of the server is wrapped up in the execution of tail recursion.
  # Tail recursion optomizes to a loop instead of a function call, thus meaning
  # it runs indefinitely.
  defp listen(val) do
    receive do
      :inc -> listen(val + 1)
      :dec -> listen(val - 1)
      {:val, sender, ref} ->
        send sender, {ref, val}
        listen(val)
    end
  end
end
