defmodule FnChess.GameServerTest do
  use ExUnit.Case, async: true

  alias FnChess.GameServer
  alias FnChess.Game
  alias FnChess.HaikuName

  test "create new game" do
    name = "game123"
    assert {:ok, game_pid} = GameServer.start_link(name)
    assert Process.alive?(game_pid)
  end

  test "update a game" do
    with name <- "game456",
         event <- {:move, origin: "a2", destination: "a4"},
         {:ok, game_pid} <- GameServer.start_link(name) do
      #
      {:ok, updated_game} = GameServer.update(name, event)
      assert Game.events(updated_game) == [event]
    end
  end

  describe "fetch" do
    test "when game exists" do
      with name <- HaikuName.generate(),
           {:ok, game_pid} <- GameServer.start_link(name) do
        #
        assert {:ok, %Game{}} = GameServer.fetch(name)
      end
    end

    test "when game doesn't exist" do
      assert {:error, :not_found} = GameServer.fetch("elvis")
    end
  end
end
