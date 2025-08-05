defmodule Person do
  use GenObject, [
    name: "",
    age: nil
  ]

  def handle_call(:test, _from, person) do
    {:reply, person, person}
  end

  def handle_call(msg, from, person) do
    super(msg, from, person)
  end
end

