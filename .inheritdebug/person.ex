defmodule Person do
  use GenServer
  use Inherit, Keyword.merge([refs: %{}, pid: nil], name: "", age: nil)
  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  defwithhold(start_link: 0, start_link: 1)
  defoverridable start_link: 0, start_link: 1
  @doc false
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts)
  end

  defwithhold(start: 0, start: 1)
  defoverridable start: 0, start: 1
  @doc false
  def child_spec(arg) do
    super(arg)
  end

  defwithhold(child_spec: 1)
  defoverridable child_spec: 1
  @doc "Create a new object with the specified fields\n"
  def new(opts \\ []) when is_list(opts) do
    case start(opts) do
      {:ok, pid} -> GenServer.call(pid, :get)
      _other -> {:error, "could not start"}
    end
  end

  defwithhold(new: 0, new: 1)
  defoverridable new: 0, new: 1

  def close(%__MODULE__{pid: pid}) do
    close(pid)
  end

  def close(pid) when is_pid(pid) do
    GenServer.stop(pid)
  end

  defwithhold(close: 1)
  defoverridable close: 1
  @doc false
  def init(opts) do
    pid = self()
    {:ok, struct(__MODULE__, Keyword.put(opts, :pid, pid))}
  end

  defwithhold(init: 1)
  defoverridable init: 1
  @doc "Delegates to `GenObject.get/1`\n"
  def get(pid_or_object) do
    GenObject.get(pid_or_object)
  end

  @doc "Delegates to `GenObject.put/3`\n"
  def put(pid, field, value) do
    GenObject.put(pid, field, value)
  end

  defwithhold(put: 3)
  defoverridable put: 3
  @doc "Delegates to `GenObject.put!/3`\n"
  def put!(pid, field, value) do
    GenObject.put!(pid, field, value)
  end

  defwithhold(put!: 3)
  defoverridable put!: 3
  @doc "Delegates to `GenObject.put_lazy/3`\n"
  def put_lazy(pid, field, func) do
    GenObject.put_lazy(pid, field, func)
  end

  defwithhold(put_lazy: 3)
  defoverridable put_lazy: 3
  @doc "Delegates to `GenObject.put_lazy!/3`\n"
  def put_lazy!(pid, field, func) do
    GenObject.put_lazy!(pid, field, func)
  end

  defwithhold(put_lazy!: 3)
  defoverridable put_lazy!: 3
  @doc "Delegates to `GenObject.merge/2`\n"
  def merge(pid, fields) do
    GenObject.merge(pid, fields)
  end

  defwithhold(merge: 2)
  defoverridable merge: 2
  @doc "Delegates to `GenObject.merge!/2`\n"
  def merge!(pid, fields) do
    GenObject.merge!(pid, fields)
  end

  defwithhold(merge!: 2)
  defoverridable merge!: 2
  @doc "Delegates to `GenObject.merge_lazy/2`\n"
  def merge_lazy(pid, func) do
    GenObject.merge_lazy(pid, func)
  end

  defwithhold(merge_lazy: 2)
  defoverridable merge_lazy: 2
  @doc "Delegates to `GenObject.merge_lazy!/2`\n"
  def merge_lazy!(pid, func) do
    GenObject.merge_lazy!(pid, func)
  end

  defwithhold(merge_lazy!: 2)
  defoverridable merge_lazy!: 2
  @doc "Delegates to `Object.handle_call/3`\n"
  def handle_call(msg, from, object) do
    GenObject.handle_call(msg, from, object)
  end

  defwithhold(handle_call: 3)
  defoverridable handle_call: 3
  @doc "Delegates to `Object.handle_cast/2`\n"
  def handle_cast(msg, object) do
    GenObject.handle_cast(msg, object)
  end

  defwithhold(handle_cast: 2)
  defoverridable handle_cast: 2
  @doc "Delegates to `Object.handle_cast/2`\n"
  def handle_info(msg, object) do
    GenObject.handle_info(msg, object)
  end

  defwithhold(handle_info: 2)
  defoverridable handle_info: 2
end