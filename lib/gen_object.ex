defmodule GenObject do
  @moduledoc """
  A library for creating stateful objects backed by GenServer processes with inheritance support.

  GenObject provides a macro-based DSL for defining object-like structures that maintain
  state in GenServer processes. Objects support field access, updates, lazy operations,
  and merging. The library integrates with the [Inherit](https://github.com/DockYard/inherit)
  library to provide inheritance modeling capabilities.

  ## Features

  - **Stateful Objects**: Objects backed by GenServer processes with automatic lifecycle management
  - **Field Operations**: Get, put, and merge operations with both synchronous and asynchronous variants
  - **Lazy Operations**: Functions that compute values based on current object state
  - **Inheritance Support**: Integration with the Inherit library for object inheritance patterns
  - **Process Safety**: All operations are process-safe through GenServer messaging

  ## Quick Start

      defmodule Person do
        use GenObject, [
          name: "",
          age: nil,
          email: nil
        ]
      end

      # Create a new person object
      person = Person.new(name: "Alice", age: 30)
      
      # Access fields
      Person.get(person, :name)  # "Alice"
      
      # Update a single field
      person = Person.put(person, :age, 31)
      
      # Update multiple fields
      person = Person.merge(person, %{name: "Alice Smith", email: "alice@example.com"})
      
      # Lazy updates based on current state
      person = Person.put_lazy(person, :age, fn p -> p.age + 1 end)

  ## Inheritance with the Inherit Library

  GenObject integrates seamlessly with the [Inherit](https://github.com/DockYard/inherit) library
  to provide object inheritance patterns. The Inherit library allows you to define parent-child
  relationships between objects and inherit fields and behaviors.

      defmodule Animal do
        use GenObject, [
          name: "",
          species: ""
        ]
      end

      defmodule Dog do
        use Animal, [
          breed: "",
          trained: false
        ]
      end

      # Dog inherits all fields from Animal plus its own
      dog = Dog.new(name: "Rex", species: "Canis lupus", breed: "Labrador")

  """

  require Logger

  @doc false
  defmacro __using__(fields) do
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
  end

  @doc """
  Retrieves the complete current state of an object.

  Returns the full object struct containing all fields and their current values.
  Accepts either a PID directly or a struct containing a `:pid` field.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field

  ## Examples

      # Using the object struct
      person = Person.new(name: "Alice", age: 30)
      current_state = GenObject.get(person)
      # Returns: %Person{name: "Alice", age: 30, pid: #PID<...>}

      # Using the PID directly  
      current_state = GenObject.get(person.pid)
      # Returns: %Person{name: "Alice", age: 30, pid: #PID<...>}

  """
  def get(%{pid: pid}) when is_pid(pid) do
    get(pid)
  end

  def get(pid) when is_pid(pid) do
    GenServer.call(pid, :get)
  end

  @doc """
  Retrieves the value of a specific field from an object.

  Returns the current value of the specified field without retrieving the entire object struct.
  This is more efficient when you only need a single field value.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `field` - The atom representing the field name to retrieve

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Get a specific field using the object struct
      name = GenObject.get(person, :name)
      # Returns: "Alice"
      
      # Get a specific field using the PID directly
      age = GenObject.get(person.pid, :age)
      # Returns: 30

  """
  def get(%{pid: pid}, field) when is_pid(pid) and is_atom(field) do
    get(pid, field)
  end

  def get(pid, field) when is_pid(pid) and is_atom(field) do
    GenServer.call(pid, {:get, field})
  end

  @doc """
  Updates a specific field in an object and returns the updated object struct.

  This is a synchronous operation that updates the field value and returns the complete
  updated object struct. The operation is atomic and thread-safe.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `field` - The atom representing the field name to update
  - `value` - The new value to set for the field

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Update using the object struct
      updated_person = GenObject.put(person, :age, 31)
      # Returns: %Person{name: "Alice", age: 31, pid: #PID<...>}
      
      # Update using the PID directly
      updated_person = GenObject.put(person.pid, :name, "Alice Smith")
      # Returns: %Person{name: "Alice Smith", age: 31, pid: #PID<...>}

  """
  def put(%{pid: pid}, field, value) when is_pid(pid) and is_atom(field) do
    put(pid, field, value)
  end

  def put(pid, field, value) when is_pid(pid) and is_atom(field) do
    GenServer.call(pid, {:put, field, value})
  end

  @doc """
  Updates a specific field in an object asynchronously and returns `:ok` immediately.

  This is an asynchronous operation that sends a cast message to update the field
  and returns immediately without waiting for confirmation. Use this when you don't
  need the updated object struct and want better performance.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `field` - The atom representing the field name to update
  - `value` - The new value to set for the field

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Async update using the object struct
      :ok = GenObject.put!(person, :age, 31)
      
      # Async update using the PID directly
      :ok = GenObject.put!(person.pid, :name, "Alice Smith")
      
      # Verify the update was applied
      updated_person = GenObject.get(person)
      # Returns: %Person{name: "Alice Smith", age: 31, pid: #PID<...>}

  """
  def put!(%{pid: pid}, field, value) when is_pid(pid) and is_atom(field) do
    put!(pid, field, value)
  end

  def put!(pid, field, value) when is_pid(pid) and is_atom(field) do
    GenServer.cast(pid, {:put, field, value})
  end

  @doc """
  Updates a specific field using a function that computes the new value based on current object state.

  This synchronous operation allows you to update a field using a function that receives
  the current object state and returns the new value for the field. Useful for updates
  that depend on the current state of the object.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `field` - The atom representing the field name to update
  - `func` - A function that takes the current object struct and returns the new value for the field

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Increment age based on current value
      updated_person = GenObject.put_lazy(person, :age, fn p -> p.age + 1 end)
      # Returns: %Person{name: "Alice", age: 31, pid: #PID<...>}
      
      # Modify name based on current state
      updated_person = GenObject.put_lazy(person.pid, :name, fn p -> 
        p.name <> " (" <> Integer.to_string(p.age) <> ")"
      end)
      # Returns: %Person{name: "Alice (30)", age: 30, pid: #PID<...>}

  """
  def put_lazy(%{pid: pid}, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    put_lazy(pid, field, func)
  end

  def put_lazy(pid, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    GenServer.call(pid, {:put_lazy, field, func})
  end

  @doc """
  Updates a specific field using a function asynchronously, returning `:ok` immediately.

  This is the asynchronous version of `put_lazy/3`. It sends a cast message to update
  the field using a function that computes the new value based on current object state,
  but returns immediately without waiting for the operation to complete.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `field` - The atom representing the field name to update
  - `func` - A function that takes the current object struct and returns the new value for the field

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Async increment age based on current value
      :ok = GenObject.put_lazy!(person, :age, fn p -> p.age + 1 end)
      
      # Async modify name based on current state
      :ok = GenObject.put_lazy!(person.pid, :name, fn p -> 
        p.name <> " (" <> Integer.to_string(p.age) <> ")"
      end)
      
      # Verify the updates were applied
      updated_person = GenObject.get(person)

  """
  def put_lazy!(%{pid: pid}, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    put_lazy!(pid, field, func)
  end

  def put_lazy!(pid, field, func) when is_pid(pid) and is_atom(field) and is_function(func) do
    GenServer.cast(pid, {:put_lazy, field, func})
  end

  defp do_put(object, field, value) do
    struct(object, %{field => value})
  end

  @doc """
  Merges multiple fields into an object and returns the updated object struct.

  This synchronous operation updates multiple fields simultaneously, similar to `struct/2`
  but for live GenObject processes. More efficient than multiple individual `put/3` calls
  when updating several fields at once.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `fields` - A map of field-value pairs to merge into the object

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Merge multiple fields using the object struct
      updated_person = GenObject.merge(person, %{
        name: "Alice Smith",
        age: 31,
        email: "alice.smith@example.com"
      })
      # Returns: %Person{name: "Alice Smith", age: 31, email: "alice.smith@example.com", pid: #PID<...>}
      
      # Merge using the PID directly
      updated_person = GenObject.merge(person.pid, %{age: 32, location: "New York"})

  """
  def merge(%{pid: pid}, fields) when is_pid(pid) and is_map(fields) do
    merge(pid, fields)
  end

  def merge(pid, fields) when is_pid(pid) and is_map(fields) do
    GenServer.call(pid, {:merge, fields})
  end

  @doc """
  Merges multiple fields into an object asynchronously, returning `:ok` immediately.

  This is the asynchronous version of `merge/2`. It sends a cast message to update
  multiple fields simultaneously but returns immediately without waiting for the
  operation to complete. Use this for better performance when you don't need the updated struct.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `fields` - A map of field-value pairs to merge into the object

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Async merge multiple fields
      :ok = GenObject.merge!(person, %{
        name: "Alice Smith",
        age: 31,
        email: "alice.smith@example.com"
      })
      
      # Verify the updates were applied
      updated_person = GenObject.get(person)
      # Returns: %Person{name: "Alice Smith", age: 31, email: "alice.smith@example.com", pid: #PID<...>}

  """
  def merge!(%{pid: pid}, fields) when is_pid(pid) and is_map(fields) do
    merge!(pid, fields)
  end

  def merge!(pid, fields) when is_pid(pid) and is_map(fields) do
    GenServer.cast(pid, {:merge, fields})
  end

  @doc """
  Merges multiple fields using a function that computes values based on current object state.

  This synchronous operation allows you to merge multiple fields using a function that
  receives the current object state and returns a map of field-value pairs to merge.
  Useful for complex updates that depend on multiple fields or computed values.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `func` - A function that takes the current object struct and returns a map of field-value pairs to merge

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Merge fields based on current state
      updated_person = GenObject.merge_lazy(person, fn p -> 
        %{
          name: p.name <> " Smith",
          age: p.age + 1,
          display_name: p.name <> " (" <> Integer.to_string(p.age + 1) <> ")"
        }
      end)
      # Returns: %Person{name: "Alice Smith", age: 31, display_name: "Alice (31)", pid: #PID<...>}
      
      # Complex computation based on multiple fields
      updated_person = GenObject.merge_lazy(person.pid, fn p ->
        age_group = if p.age < 18, do: "minor", else: "adult"
        %{age_group: age_group, can_vote: p.age >= 18}
      end)

  """
  def merge_lazy(%{pid: pid}, func) when is_pid(pid) and is_function(func) do
    merge_lazy(pid, func)
  end
  
  def merge_lazy(pid, func) when is_pid(pid) and is_function(func) do
    GenServer.call(pid, {:merge_lazy, func})
  end

  @doc """
  Merges multiple fields using a function asynchronously, returning `:ok` immediately.

  This is the asynchronous version of `merge_lazy/2`. It sends a cast message to merge
  multiple fields using a function that computes values based on current object state,
  but returns immediately without waiting for the operation to complete.

  ## Parameters

  - `pid_or_object` - The PID of the GenObject process, or an object struct containing a `:pid` field
  - `func` - A function that takes the current object struct and returns a map of field-value pairs to merge

  ## Examples

      person = Person.new(name: "Alice", age: 30)
      
      # Async merge fields based on current state
      :ok = GenObject.merge_lazy!(person, fn p -> 
        %{
          name: p.name <> " Smith",
          age: p.age + 1,
          display_name: p.name <> " (" <> Integer.to_string(p.age + 1) <> ")"
        }
      end)
      
      # Verify the updates were applied
      updated_person = GenObject.get(person)
      # Returns: %Person{name: "Alice Smith", age: 31, display_name: "Alice (31)", pid: #PID<...>}

  """
  def merge_lazy!(%{pid: pid}, func) when is_pid(pid) and is_function(func) do
    merge_lazy!(pid, func)
  end

  def merge_lazy!(pid, func) when is_pid(pid) and is_function(func) do
    GenServer.cast(pid, {:merge_lazy, func})
  end

  defp do_merge(object, fields) do
    Map.merge(object, fields)
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
