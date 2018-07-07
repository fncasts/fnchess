defmodule FnChess.GameTest do
  use ExUnit.Case, async: true

  alias FnChess.Game

  test "create new game" do
    game = Game.new()
    assert Game.events(game) == []
  end

  test "update event" do
    {:ok, updated_game} =
      Game.new()
      |> Game.update({:move, origin: "a2", destination: "a4"})

    assert Game.events(updated_game) == [{:move, origin: "a2", destination: "a4"}]
  end
end
