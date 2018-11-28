defmodule ExtensibleElixirTest do
  use ExUnit.Case
  doctest ExtensibleElixir

  test "greets the world" do
    assert ExtensibleElixir.hello() == :world
  end
end
