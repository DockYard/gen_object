defmodule Person do
  use GenObject, [
    first_name: "",
    last_name: "",
    age: nil,
  ]

  def handle_call(:test, _from, person) do
    {:reply, person, person}
  end

  def handle_call(msg, from, person) do
    super(msg, from, person)
  end

  def handle_get(:name, object) do
    "#{object.first_name} #{object.last_name}"
  end

  def handle_get(field, object) do
    super(field, object)
  end

  def handle_set({:name, name}, person) do
    [first_name, last_name] = String.split(name, " ")
    Map.merge(person, %{first_name: first_name, last_name: last_name})
  end

  def handle_set(pair, object) do
    super(pair, object)
  end
end

