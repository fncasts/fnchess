defmodule FnChess.GameSupervisorTest do
  use ExUnit.Case, async: true

  alias FnChess.GameSupervisor
  alias FnChess.GameServer
  alias FnChess.Game

  test "start game" do
    name = "game1245"
    assert {:ok, pid} = GameSupervisor.start_game(name)

    assert Process.alive?(pid)
  end

  test "terminate game" do
    name = "game4567"
    {:ok, pid} = GameSupervisor.start_game(name)
    :ok = GameSupervisor.stop_game(name)

    refute Process.alive?(pid)
  end
end
