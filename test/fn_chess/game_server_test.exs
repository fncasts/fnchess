defmodule FnChess.GameServerTest do
  use ExUnit.Case, async: true

  alias FnChess.GameServer
  alias FnChess.Game

  test "create new game" do
    name = "game123"
    assert {:ok, game_pid} = GameServer.start_link(name)
    assert Process.alive?(game_pid)
  end

  test "update a game" do
    name = "game456"
    event = {:move, origin: "a2", destination: "a4"}
    {:ok, game_pid} = GameServer.start_link(name)
    {:ok, updated_game} = GameServer.update(name, event)
    assert Game.events(updated_game) == [event]
  end
end
