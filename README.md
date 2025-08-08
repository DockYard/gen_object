# GenObject

A library for creating stateful objects backed by GenServer processes with inheritance support.

GenObject provides a macro-based DSL for defining object-like structures that maintain state in GenServer processes. Objects support field access, updates, lazy operations, and merging. The library uses the [Inherit](https://github.com/DockYard/inherit) library to provide powerful inheritance modeling capabilities.

## Features

- **Stateful Objects**: Objects backed by GenServer processes with automatic lifecycle management
- **Field Operations**: Get, put, and merge operations with both synchronous and asynchronous variants
- **Lazy Operations**: Functions that compute values based on current object state
- **Inheritance Support**: Inherit library for object inheritance patterns
- **Process Safety**: All operations are process-safe through GenServer messaging
- **Performance**: Asynchronous variants for high-performance scenarios

## Installation

Add `gen_object` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_object, "~> 0.2.1"}
  ]
end
```

## Quick Start

### Basic Object Definition

```elixir
defmodule Person do
  use GenObject, [
    name: "",
    age: nil,
    email: nil
  ]
end

# Create a new person object
person = Person.new(name: "Alice", age: 30)
# Returns: %Person{name: "Alice", age: 30, email: nil, pid: #PID<...>}
```

### Field Access

```elixir
# Get the complete object
current_person = Person.get(person)
# Returns: %Person{name: "Alice", age: 30, email: nil, pid: #PID<...>}

# Get a specific field (more efficient)
name = Person.get(person, :name)
# Returns: "Alice"

# Can also use PID directly
age = Person.get(person.pid, :age)
# Returns: 30
```

### Field Updates

```elixir
# Synchronous update (returns updated object)
person = Person.put(person, :age, 31)
person = Person.put(person.pid, :email, "alice@example.com")

# Asynchronous update (returns :ok immediately)
:ok = Person.put!(person, :age, 32)
:ok = Person.put!(person.pid, :name, "Alice Smith")

# Verify async updates
updated_person = Person.get(person)
```

### Lazy Updates

Lazy updates allow you to compute new values based on the current object state:

```elixir
# Increment age based on current value
person = Person.put_lazy(person, :age, fn p -> p.age + 1 end)

# Create display name from existing fields
person = Person.put_lazy(person, :display_name, fn p ->
  "#{p.name} (#{p.age})"
end)

# Asynchronous lazy update
:ok = Person.put_lazy!(person, :age, fn p -> p.age + 1 end)
```

### Merging Multiple Fields

```elixir
# Synchronous merge
person = Person.merge(person, %{
  name: "Alice Johnson",
  age: 35,
  email: "alice.johnson@example.com",
  location: "San Francisco"
})

# Asynchronous merge
:ok = Person.merge!(person, %{age: 36, location: "New York"})

# Lazy merge based on current state
person = Person.merge_lazy(person, fn p ->
  age_group = if p.age < 18, do: "minor", else: "adult"
  %{
    age_group: age_group,
    can_vote: p.age >= 18,
    display_name: "#{p.name} (#{age_group})"
  }
end)
```

## Inheritance with the Inherit Library

GenObject uses the [Inherit](https://github.com/DockYard/inherit) library to provide powerful inheritance modeling:

### Basic Inheritance

```elixir
defmodule Animal do
  use GenObject, [
    name: "",
    species: "",
    age: 0
  ]
  
  def speak(%__MODULE__{} = animal) do
    "#{animal.name} makes a sound"
  end
end

defmodule Dog do
  use Animal, [
    breed: "",
    trained: false
  ]
  
  # Override parent method
  def speak(%__MODULE__{} = dog) do
    "#{dog.name} barks! Woof!"
  end
  
  def sit(%__MODULE__{trained: true} = dog) do
    Dog.put(dog, :position, :sitting)
  end
  
  def sit(%__MODULE__{trained: false} = dog) do
    {:error, "#{dog.name} is not trained to sit"}
  end
end

# Dog inherits all fields from Animal plus its own
dog = Dog.new(
  name: "Rex", 
  species: "Canis lupus", 
  breed: "Labrador", 
  age: 3,
  trained: true
)

# Use inherited and own methods
Dog.speak(dog)  # "Rex barks! Woof!"
Dog.sit(dog)    # Updates position to :sitting
```

### Multi-level Inheritance

```elixir
defmodule LivingThing do
  use GenObject, [
    alive: true,
    birth_date: nil
  ]
end

defmodule Animal do
  use LivingThing, [
    name: "",
    species: ""
  ]
end

defmodule Mammal do
  use Animal, [
    warm_blooded: true,
    fur_color: nil
  ]
end

defmodule Dog do
  use Mammal, [
    breed: "",
    trained: false
  ]
end

# Dog inherits from the entire chain
dog = Dog.new(
  name: "Buddy",
  species: "Canis lupus",
  breed: "Golden Retriever",
  fur_color: "golden",
  birth_date: ~D[2020-01-15],
  trained: true
)
```

### Complex Inheritance Patterns

```elixir
defmodule Vehicle do
  use GenObject, [
    make: "",
    model: "",
    year: nil,
    mileage: 0
  ]
  
  def drive(%__MODULE__{} = vehicle, distance) do
    Vehicle.put_lazy(vehicle, :mileage, fn v -> v.mileage + distance end)
  end
end

defmodule Car do
  use Vehicle, [
    doors: 4,
    fuel_type: :gasoline
  ]
  
  def honk(%__MODULE__{} = car) do
    "#{car.make} #{car.model} honks: BEEP BEEP!"
  end
end

defmodule ElectricCar do
  use Car, [
    battery_capacity: 0,
    charge_level: 100,
    fuel_type: :electric  # Override parent default
  ]
  
  def charge(%__MODULE__{} = car, amount) do
    ElectricCar.put_lazy(car, :charge_level, fn c ->
      min(100, c.charge_level + amount)
    end)
  end
  
  # Override parent method
  def drive(%__MODULE__{} = car, distance) do
    car = super(car, distance)  # Call parent implementation
    # Reduce charge based on distance
    ElectricCar.put_lazy(car, :charge_level, fn c ->
      max(0, c.charge_level - div(distance, 10))
    end)
  end
end

# Create an electric car with full inheritance chain
tesla = ElectricCar.new(
  make: "Tesla",
  model: "Model 3",
  year: 2023,
  battery_capacity: 75,
  doors: 4
)

# Use methods from all levels of inheritance
tesla = ElectricCar.drive(tesla, 100)    # Inherited and overridden
tesla = ElectricCar.charge(tesla, 20)    # Own method
message = Car.honk(tesla)                # Parent method
```

## Advanced Usage

### Custom GenServer Callbacks

You can override GenServer callbacks while still using GenObject functionality:

```elixir
defmodule TimestampedObject do
  use GenObject, [
    data: nil,
    created_at: nil,
    updated_at: nil
  ]
  
  # Override init to set timestamps
  def init(opts) do
    now = DateTime.utc_now()
    opts = opts
    |> Keyword.put(:created_at, now)
    |> Keyword.put(:updated_at, now)
    
    super(opts)  # Call GenObject's init
  end
  
  # Override handle_call to update timestamps
  def handle_call({:put, field, value}, from, object) do
    result = super({:put, field, value}, from, object)
    case result do
      {:reply, updated_object, state} ->
        updated_state = TimestampedObject.put(state, :updated_at, DateTime.utc_now())
        {:reply, updated_object, updated_state}
      other -> other
    end
  end
end
```

### Supervision

GenObjects can be supervised like any GenServer:

```elixir
defmodule MyApp.ObjectSupervisor do
  use Supervisor
  
  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def init([]) do
    children = [
      {Person, [name: "Default Person"]},
      {Dog, [name: "Default Dog", breed: "Mixed"]}
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

## Performance Considerations

- Use asynchronous operations (`put!/3`, `merge!/2`, etc.) when you don't need the return value
- Use `get/2` for single fields instead of `get/1` when you only need one field
- Batch multiple updates using `merge/2` instead of multiple `put/3` calls
- Lazy operations are computed synchronously, so complex computations may block

## API Reference

### Creation and Lifecycle
- `YourModule.new/1` - Create a new object
- `YourModule.close/1` - Stop the object process

### Field Access
- `YourModule.get/1` - Get complete object state
- `YourModule.get/2` - Get specific field value

### Field Updates  
- `YourModule.put/3` - Update field synchronously
- `YourModule.put!/3` - Update field asynchronously
- `YourModule.put_lazy/3` - Update field with function synchronously
- `YourModule.put_lazy!/3` - Update field with function asynchronously

### Bulk Operations
- `YourModule.merge/2` - Merge multiple fields synchronously
- `YourModule.merge!/2` - Merge multiple fields asynchronously
- `YourModule.merge_lazy/2` - Merge with function synchronously
- `YourModule.merge_lazy!/2` - Merge with function asynchronously

All functions accept either a PID or an object struct containing a `:pid` field. Replace `YourModule` with your actual module name (e.g., `Person`, `Dog`, etc.).

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)  
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.
