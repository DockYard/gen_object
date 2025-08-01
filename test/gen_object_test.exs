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
      person = %Person{} = Person.new(name: "Brian")
      assert Person.get(person, :name) == "Brian"
    end

    test "with pid" do
      %Person{pid: pid} = Person.new(name: "Brian")
      assert Person.get(pid, :name) == "Brian"
    end
  end

  describe "put" do
    test "sync" do
      person = Person.new()
      person = Person.put(person, :age, 99)
      assert person.age == 99

      person = Person.put(person.pid, :age, 23)
      assert person.age == 23
    end

    test "async" do
      person = Person.new()
      :ok = Person.put!(person, :age, 99)
      person = Person.get(person)
      assert person.age == 99

      :ok = Person.put!(person.pid, :age, 23)
      person = Person.get(person)
      assert person.age == 23
    end
  end

  describe "put_lazy" do
    test "sync" do
      person = Person.new()
      person = Person.put_lazy(person, :age, fn(person) ->
        person.age || 99
      end)
      assert person.age == 99

      person = Person.put_lazy(person.pid, :age, fn(person) ->
        person.age + 10
      end)
      assert person.age == 109
    end

    test "async" do
      person = Person.new()
      :ok = Person.put_lazy!(person, :age, fn(person) ->
        person.age || 99
      end)
      person = Person.get(person)
      assert person.age == 99

      :ok = Person.put_lazy!(person.pid, :age, fn(person) ->
        person.age + 10
      end)
      person = Person.get(person)
      assert person.age == 109
    end
  end

  describe "merge" do
    test "sync" do
      person = Person.new()
      person = Person.merge(person, %{age: 99, name: "Thomas"})
      assert person.age == 99
      assert person.name == "Thomas"

      person = Person.merge(person.pid, %{age: 23, name: "Brian"})
      assert person.age == 23
      assert person.name == "Brian"
    end

    test "async" do
      person = Person.new()
      :ok = Person.merge!(person, %{age: 99, name: "Thomas"})
      person = Person.get(person)
      assert person.age == 99
      assert person.name == "Thomas"

      :ok = Person.merge!(person.pid, %{age: 23, name: "Brian"})
      person = Person.get(person)
      assert person.age == 23
      assert person.name == "Brian"
    end
  end

  describe "merge_lazy" do
    test "sync" do
      person = Person.new()
      person = Person.merge_lazy(person, fn(person) ->
        Map.put(person, :age, 99)
      end)
      assert person.age == 99

      person = Person.merge_lazy(person.pid, fn(person) ->
       %{age: person.age + 10, name: "Thomas"} 
      end)
      assert person.age == 109
      assert person.name == "Thomas"
    end

    test "async" do
      person = Person.new()
      :ok = Person.merge_lazy!(person, fn(person) ->
        Map.put(person, :age, 99)
      end)
      person = Person.get(person)
      assert person.age == 99

      :ok = Person.merge_lazy!(person.pid, fn(person) ->
        %{age: person.age + 10, name: "Brian"}
      end)
      person = Person.get(person)
      assert person.age == 109
      assert person.name == "Brian"
    end
  end
end
