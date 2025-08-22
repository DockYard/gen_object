defmodule GenObjectTest do
  use ExUnit.Case

  test "can create a new object" do
    %Person{pid: pid} = Person.new()
    assert Process.alive?(pid)
  end

  describe "get/1" do
    test "with struct" do
      person = %Person{} = Person.new()
      assert Person.get(person) == person
    end

    test "with pid" do
      person = %Person{pid: pid} = Person.new()
      assert Person.get(pid) == person
    end
  end

  describe "get/2" do
    test "with struct" do
      person = %Person{} = Person.new(first_name: "Brian")
      assert Person.get(person, :first_name) == "Brian"
    end

    test "with pid" do
      %Person{pid: pid} = Person.new(first_name: "Brian")
      assert Person.get(pid, :first_name) == "Brian"
    end
  end

  describe "get/2 with list of fields" do
    test "with struct" do
      person = %Person{} = Person.new(first_name: "Brian", last_name: "Cardarella")
      assert Person.get(person, [:first_name, :last_name]) == ["Brian", "Cardarella"]
    end

    test "with pid" do
      %Person{pid: pid} = Person.new(first_name: "Brian", last_name: "Cardarella")
      assert Person.get(pid, [:first_name, :last_name]) == ["Brian", "Cardarella"]
    end
  end

  describe "set" do
    test "sync" do
      person = Person.new()
      person = Person.set(person, :age, 99)
      assert Person.get(person, :age) == 99

      _person = Person.set(person.pid, :age, 23)
      assert Person.get(person, :age) == 23
    end

    test "async" do
      person = Person.new()
      :ok = Person.set!(person, :age, 99)
      assert Person.get(person, :age) == 99

      :ok = Person.set!(person.pid, :age, 23)
      assert Person.get(person, :age) == 23
    end
  end

  describe "set_lazy" do
    test "sync" do
      person = Person.new()
      person = Person.set_lazy(person, :age, fn(person) ->
        person.age || 99
      end)
      assert Person.get(person, :age) == 99

      _person = Person.set_lazy(person.pid, :age, fn(person) ->
        person.age + 10
      end)
      assert Person.get(person, :age) == 109
    end

    test "async" do
      person = Person.new()
      :ok = Person.set_lazy!(person, :age, fn(person) ->
        person.age || 99
      end)
      assert Person.get(person, :age) == 99

      :ok = Person.set_lazy!(person.pid, :age, fn(person) ->
        person.age + 10
      end)
      assert Person.get(person, :age) == 109
    end
  end

  describe "merge" do
    test "sync" do
      person = Person.new()
      person = Person.merge(person, %{age: 99, first_name: "Thomas"})
      assert Person.get(person, :age) == 99
      assert Person.get(person, :first_name) == "Thomas"

      person = Person.merge(person.pid, %{age: 23, first_name: "Brian"})
      assert Person.get(person, :age) == 23
      assert Person.get(person, :first_name) == "Brian"
    end

    test "async" do
      person = Person.new()
      :ok = Person.merge!(person, %{age: 99, first_name: "Thomas"})
      assert Person.get(person, :age) == 99
      assert Person.get(person, :first_name) == "Thomas"

      :ok = Person.merge!(person.pid, %{age: 23, first_name: "Brian"})
      assert Person.get(person, :age) == 23
    end
  end

  describe "merge_lazy" do
    test "sync" do
      person = Person.new()
      person = Person.merge_lazy(person, fn(_person) ->
        %{age: 99, first_name: "Thomas"}
      end)
      assert Person.get(person, :age) == 99
      assert Person.get(person, :first_name) == "Thomas"

      _person = Person.merge_lazy(person.pid, fn(_person) ->
        %{age: person.age + 10, first_name: "Brian"} 
      end)
      assert Person.get(person, :age) == 109
      assert Person.get(person, :first_name) == "Brian"
    end

    test "async" do
      person = Person.new()
      :ok = Person.merge_lazy!(person, fn(_person) ->
        %{age: 99, first_name: "Thomas"}
      end)
      assert Person.get(person, :age) == 99
      assert Person.get(person, :first_name) == "Thomas"

      :ok = Person.merge_lazy!(person.pid, fn(person) ->
        %{age: person.age + 10, first_name: "Brian"}
      end)
      assert Person.get(person, :age) == 109
      assert Person.get(person, :first_name) == "Brian"
    end
  end

  test "inherited modules inherit GenServer behaviour" do
    athlete = Athlete.new(first_name: "Brian", sport: "Baseball")
    assert is_pid(athlete.pid)
  end

  describe "virtual attributes" do
    test "get a virtual attribute calculated a value instead of gets" do
      person = Person.new(first_name: "Brian", last_name: "Cardarella")
      assert Person.get(person, :name) == "Brian Cardarella"
    end

    test "set a virtual attribute can set state values" do
      person = Person.new()
      Person.set(person, :name, "Brian Cardarella")

      assert Person.get(person, :first_name) == "Brian"
      assert Person.get(person, :last_name) == "Cardarella"
    end

    test "merge virtual attributes" do
      person = Person.new()
      Person.merge(person, %{name: "Brian Cardarella"})

      assert Person.get(person, :first_name) == "Brian"
      assert Person.get(person, :last_name) == "Cardarella"
    end
  end
end
