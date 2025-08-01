defmodule GenObject do
  @moduledoc """
  A behaviour for creating stateful objects backed by GenServer processes.

  This module provides a macro `__using__/1` that generates functions for managing
  object state through GenServer calls and casts. GenObjects created with this module
  support field updates, lazy updates, and merging operations.

  ## Usage

      defmodule MyObject do
        use GenObject, [:name, :value]
      end

      # Create a new object
      {:ok, obj} = MyObject.new(name: "test", value: 42)

      # Update fields
      updated_obj = MyObject.put(obj.pid, :name, "updated")

  """

  require Logger

  @doc false
  defmacro __using__(fields) do
    # {fields, children} =
    #   Macro.expand(fields, __CALLER__)
    #   |> Enum.split_with(fn
    #   {_name, default} when is_atom(default) ->
    #     case Atom.to_string(default) do
    #       <<"Elixir.", _module::binary>> -> false
    #       _other -> true
    #     end
    #   {_name, [default]} when is_atom(default) ->
    #     case Atom.to_string(default) do
    #       <<"Elixir.", _module::binary>> -> false
    #       _other -> true
    #     end
    #
    #   _other -> true
    # end)

    quote do
      use GenServer
      use Inherit, Keyword.merge([
        refs: %{},
        pid: nil,
      ], unquote(fields))

      @doc false
      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts)
      end
      defwithhold start_link: 0, start_link: 1
      defoverridable start_link: 0, start_link: 1

      @doc false
      def start(opts \\ []) do
        GenServer.start(__MODULE__, opts)
      end
      defwithhold start: 0, start: 1
      defoverridable start: 0, start: 1

      @doc false
      def child_spec(arg) do
        super(arg)
      end
      defwithhold child_spec: 1
      defoverridable child_spec: 1

      @doc """
      Create a new object with the specified fields
      """
      def new(opts \\ []) when is_list(opts) do
        case start(opts) do
          {:ok, pid} -> GenServer.call(pid, :get)
          _other -> {:error, "could not start"}
        end
      end
      defwithhold new: 0, new: 1
      defoverridable new: 0, new: 1

      def close(%__MODULE__{pid: pid}) do
        close(pid)
      end
      def close(pid) when is_pid(pid) do
        GenServer.stop(pid)
      end
      defwithhold close: 1
      defoverridable close: 1

      @doc false
      def init(opts) do
        pid = self()
        # :pg.start_link()
        # :pg.monitor(pid)

        {:ok, struct(__MODULE__, Keyword.put(opts, :pid, pid))}
      end
      defwithhold init: 1
      defoverridable init: 1

      @doc """
      Delegates to `GenObject.get/1`
      """
      def get(pid_or_object) do
        GenObject.get(pid_or_object)
      end

      @doc """
      Delegates to `GenObject.get/1`
      """
      def get(pid_or_object, field) do
        GenObject.get(pid_or_object, field)
      end

      @doc """
      Delegates to `GenObject.put/3`
      """
      def put(pid, field, value) do
        GenObject.put(pid, field, value)
      end
      defwithhold put: 3
      defoverridable put: 3

      @doc """
      Delegates to `GenObject.put!/3`
      """
      def put!(pid, field, value) do
        GenObject.put!(pid, field, value)
      end
      defwithhold put!: 3
      defoverridable put!: 3

      @doc """
      Delegates to `GenObject.put_lazy/3`
      """
      def put_lazy(pid, field, func) do
        GenObject.put_lazy(pid, field, func)
      end
      defwithhold put_lazy: 3
      defoverridable put_lazy: 3

      @doc """
      Delegates to `GenObject.put_lazy!/3`
      """
      def put_lazy!(pid, field, func) do
        GenObject.put_lazy!(pid, field, func)
      end
      defwithhold put_lazy!: 3
      defoverridable put_lazy!: 3

      @doc """
      Delegates to `GenObject.merge/2`
      """
      def merge(pid, fields) do
        GenObject.merge(pid, fields)
      end
      defwithhold merge: 2
      defoverridable merge: 2

      @doc """
      Delegates to `GenObject.merge!/2`
      """
      def merge!(pid, fields) do
        GenObject.merge!(pid, fields)
      end
      defwithhold merge!: 2
      defoverridable merge!: 2

      @doc """
      Delegates to `GenObject.merge_lazy/2`
      """
      def merge_lazy(pid, func) do
        GenObject.merge_lazy(pid, func)
      end
      defwithhold merge_lazy: 2
      defoverridable merge_lazy: 2

      @doc """
      Delegates to `GenObject.merge_lazy!/2`
      """
      def merge_lazy!(pid, func) do
        GenObject.merge_lazy!(pid, func)
      end
      defwithhold merge_lazy!: 2
      defoverridable merge_lazy!: 2

      @doc """
      Delegates to `Object.handle_call/3`
      """
      def handle_call(msg, from, object) do
        GenObject.handle_call(msg, from, object)
      end
      defwithhold handle_call: 3
      defoverridable handle_call: 3

      @doc """
      Delegates to `Object.handle_cast/2`
      """
      def handle_cast(msg, object) do
        GenObject.handle_cast(msg, object)
      end
      defwithhold handle_cast: 2
      defoverridable handle_cast: 2

      @doc """
      Delegates to `Object.handle_cast/2`
      """
      def handle_info(msg, object) do
        GenObject.handle_info(msg, object)
      end
      defwithhold handle_info: 2
      defoverridable handle_info: 2
    end
    |> Inherit.debug(__CALLER__)
  end

  @doc """
  Retrieves the current state of an object.

  This function returns the current object struct for the given PID.

  ## Parameters

  - `pid` - The PID of the object or a struct containing a PID

  ## Examples

      iex> {:ok, obj} = MyObject.new([])
      iex> current_state = GenObject.get(obj.pid)
      iex> %MyObject{} = current_state

  """
  def get(%{pid: pid}) when is_pid(pid) do
    get(pid)
  end

  def get(pid) when is_pid(pid) do
    GenServer.call(pid, :get)
  end

  @doc """
  Retrieves the current state of an object.

  This function returns the current object struct for the given PID.

  ## Parameters

  - `pid` - The PID of the object or a struct containing a PID

  ## Examples

      iex> {:ok, obj} = MyObject.new([])
      iex> current_state = GenObject.get(obj.pid)
      iex> %MyObject{} = current_state

  """
  def get(%{pid: pid}, field) when is_pid(pid) and is_atom(field) do
    get(pid, field)
  end

  def get(pid, field) when is_pid(pid) and is_atom(field) do
    GenServer.call(pid, {:get, field})
  end

  @doc """
  Updates a specific field in the state struct and returns the updated struct.

  This function directly modifies a field in the struct stored in the process.

  ## Parameters

  - `pid` - The PID of the object
  - `field` - The field name to update
  - `value` - The new value for the field

  ## Examples

      iex> {:ok, obj} = MyObject.new([])
      iex> updated_obj = GenObject.put(obj.pid, :name, "Hello World")
      iex> updated_obj.name
      "Hello World"

  """
  def put(%{pid: pid}, field, value) when is_pid(pid) and is_atom(field) do
    put(pid, field, value)
  end

  def put(pid, field, value) when is_pid(pid) and is_atom(field) do
    GenServer.call(pid, {:put, field, value})
  end

  @doc """
  Updates a specific field in the state struct asynchronously and immediately returns `:ok`.

  This function directly modifies a field in the struct stored in the process
  but does not return the updated struct.

  ## Parameters

  - `pid` - The PID of the object
  - `field` - The field name to update
  - `value` - The new value for the field

  ## Examples

      iex> {:ok, object} = MyObject.new([])
      iex> :ok = GenObject.put!(object.pid, :name, "Hello World")
      :ok

  """
  def put!(%{pid: pid}, field, value) when is_pid(pid) and is_atom(field) do
    put!(pid, field, value)
  end

  def put!(pid, field, value) when is_pid(pid) and is_atom(field) do
    GenServer.cast(pid, {:put, field, value})
  end

  @doc """
  Updates a specific field in the object struct using a function and returns the updated struct.

  This function allows you to update a field based on the current state of the object.
  The function receives the current object as an argument and should return the new value for the field.

  ## Parameters

  - `pid` - The PID of the object
  - `field` - The field name to update
  - `func` - A function that takes the current object and returns the new value for the field

  ## Examples

      iex> {:ok, obj} = MyObject.new([name: "Hello"])
      iex> updated_obj = GenObject.put_lazy(obj.pid, :name, fn obj -> 
      ...>   obj.name <> " World"
      ...> end)
      iex> updated_obj.name
      "Hello World"

  """
  def put_lazy(%{pid: pid}, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    put_lazy(pid, field, func)
  end

  def put_lazy(pid, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    GenServer.call(pid, {:put_lazy, field, func})
  end

  @doc """
  Updates a specific field in the object struct using a function asynchronously without returning a value.

  This function is the asynchronous version of `put_lazy/3`. It allows you to update a field
  based on the current state of the object but doesn't wait for a response.

  ## Parameters

  - `pid` - The PID of the object
  - `field` - The field name to update
  - `func` - A function that takes the current object and returns the new value for the field

  ## Examples

      iex> {:ok, obj} = MyObject.new([name: "Hello"])
      iex> :ok = GenObject.put_lazy!(obj.pid, :name, fn obj -> 
      ...>   obj.name <> " World"
      ...> end)
      :ok

  """
  def put_lazy!(%{pid: pid}, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    put_lazy!(pid, field, func)
  end

  def put_lazy!(pid, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    GenServer.cast(pid, {:put_lazy, field, func})
  end

  defp do_put(object, field, value) do
    struct(object, %{field => value})

    # allowed_fields = apply(object.__struct__, :allowed_fields, [])

    # if field in allowed_fields  && node.owner_document do
    #   GenServer.cast(node.owner_document, {:send_to_receiver, {:put, self(), field, value}})
    # end
  end

  @doc """
  Merges multiple fields into the object struct and returns the updated object.

  This function updates multiple fields in the object struct at once, similar to `struct/2`
  but for live objects. Use this when you need to update several fields simultaneously.

  ## Parameters

  - `pid` - The PID of the object
  - `fields` - A map or keyword list of field-value pairs to merge

  ## Examples

      iex> {:ok, obj} = MyObject.new([])
      iex> updated_obj = GenObject.merge(obj.pid, %{
      ...>   name: "Hello World",
      ...>   value: 42
      ...> })
      iex> updated_obj.name
      "Hello World"
      iex> updated_obj.value
      42

  """
  def merge(%{pid: pid}, fields) when is_pid(pid) and is_map(fields) do
    merge(pid, fields)
  end

  def merge(pid, fields) when is_pid(pid) and is_map(fields) do
    GenServer.call(pid, {:merge, fields})
  end

  @doc """
  Merges multiple fields into the object struct asynchronously without returning a value.

  This function is the asynchronous version of `merge/2`. It updates multiple fields in the
  object struct at once but doesn't wait for a response.

  ## Parameters

  - `pid` - The PID of the object
  - `fields` - A map or keyword list of field-value pairs to merge

  ## Examples

      iex> {:ok, obj} = MyObject.new([])
      iex> :ok = GenObject.merge!(obj.pid, %{
      ...>   name: "Hello World",
      ...>   value: 42
      ...> })
      :ok

  """
  def merge!(%{pid: pid}, fields) when is_pid(pid) and is_map(fields) do
    merge!(pid, fields)
  end

  def merge!(pid, fields) when is_pid(pid) and is_map(fields) do
    GenServer.cast(pid, {:merge, fields})
  end

  @doc """
  Merges multiple fields into the object struct using a function and returns the updated object.

  This function allows you to merge fields based on the current state of the object.
  The function receives the current object as an argument and should return a map of
  field-value pairs to merge.

  ## Parameters

  - `pid` - The PID of the object
  - `func` - A function that takes the current object and returns a map of fields to merge

  ## Examples

      iex> {:ok, obj} = MyObject.new([name: "Hello"])
      iex> updated_obj = GenObject.merge_lazy(obj.pid, fn obj -> 
      ...>   %{
      ...>     name: obj.name <> " World",
      ...>     value: String.length(obj.name)
      ...>   }
      ...> end)
      iex> updated_obj.name
      "Hello World"

  """
  def merge_lazy(%{pid: pid}, func) when is_pid(pid) and is_function(func) do
    merge_lazy(pid, func)
  end
  
  def merge_lazy(pid, func) when is_pid(pid) and is_function(func) do
    GenServer.call(pid, {:merge_lazy, func})
  end

  @doc """
  Merges multiple fields into the object struct using a function asynchronously without returning a value.

  This function is the asynchronous version of `merge_lazy/2`. It allows you to merge fields
  based on the current state of the object but doesn't wait for a response.

  ## Parameters

  - `pid` - The PID of the object
  - `func` - A function that takes the current object and returns a map of fields to merge

  ## Examples

      iex> {:ok, obj} = MyObject.new([name: "Hello"])
      iex> :ok = GenObject.merge_lazy!(obj.pid, fn obj -> 
      ...>   %{
      ...>     name: obj.name <> " World",
      ...>     value: String.length(obj.name)
      ...>   }
      ...> end)
      :ok

  """
  def merge_lazy!(%{pid: pid}, func) when is_pid(pid) and is_function(func) do
    merge_lazy!(pid, func)
  end

  def merge_lazy!(pid, func) when is_pid(pid) and is_function(func) do
    GenServer.cast(pid, {:merge_lazy, func})
  end

  defp do_merge(object, fields) do
    Map.merge(object, fields)

    # if node.owner_document do
    #   allowed_fields = apply(node.__struct__, :allowed_fields, [])
    #   fields = Map.drop(fields, allowed_fields)
    #
    #   if !Enum.empty?(fields) do
    #     GenServer.cast(node.owner_document, {:send_to_receiver, {:merge, self(), fields}})
    #   end
    # end
    #
    # node
  end

  @doc false
  def handle_call(:get, _from, object) do
    {:reply, object, object}
  end

  def handle_call({:get, field}, _from, object) do
    {:reply, Map.get(object, field), object}
  end

  def handle_call({:assign, assigns}, _from, object) when is_map(assigns) do
    object = struct(object, assigns: Map.merge(object.assigns, assigns))
    {:reply, object.pid, object}
  end

  def handle_call({:merge, fields}, _from, object) do
    object = do_merge(object, fields)
    {:reply, object, object}
  end

  def handle_call({:merge_lazy, func}, _from, object) when is_function(func) do
    fields = func.(object)
    object = do_merge(object, fields)
    {:reply, object, object}
  end

  def handle_call({:put, field, value}, _from, object) do
    object = do_put(object, field, value)
    {:reply, object, object}
  end

  def handle_call({:put_lazy, field, func}, _from, object) when is_function(func) do
    value = func.(object)
    object = do_put(object, field, value)
    {:reply, object, object}
  end

  def handle_call(msg, _from, object) do
    Logger.warning("unhandled messge: #{msg}")
    {:reply, :ok, object}
  end

  @doc false
  def handle_cast({:put, field, value}, object) do
    object = do_put(object, field, value)
    {:noreply, object}
  end

  def handle_cast({:put_lazy, field, func}, object) when is_function(func) do
    value = func.(object)
    object = do_put(object, field, value)
    {:noreply, object}
  end

  def handle_cast({:merge, fields}, object) do
    object = do_merge(object, fields)
    {:noreply, object}
  end

  def handle_cast({:merge_lazy, func}, object) when is_function(func) do
    fields = func.(object)
    object = do_merge(object, fields)
    {:noreply, object}
  end

  def handle_cast(msg, object) do
    Logger.warning("unhandled message #{msg}")
    {:noreply, object}
  end

  def handle_info(msg, object) do
    Logger.warning("unhandled message #{msg}")
    {:noreply, object}
  end

  defoverridable handle_info: 2
end
