defmodule FnChessWeb.GameChannelTest do
  use FnChessWeb.ChannelCase

  alias FnChess.Game
  alias FnChess.GameServer
  alias FnChess.GameSupervisor
  alias FnChessWeb.GameChannel
  alias FnChessWeb.GamesChannel
  alias FnChessWeb.UserSocket

  @user_id "jimbo"

  def user_socket() do
    connect(UserSocket, %{"user_id" => @user_id})
  end

  def start_game() do
    game_name = FnChess.HaikuName.generate()
    {:ok, game_pid} = GameSupervisor.start_game(game_name)
    {:ok, game_name}
  end

  describe "on join" do
    test "when game exists" do
      with {:ok, socket} <- user_socket(),
           {:ok, game_name} <- start_game() do
        #
        {:ok, game_reply, socket} = subscribe_and_join(socket, GameChannel, "game:#{game_name}")

        assert {:ok, game_reply} == GameServer.fetch(game_name)
      end
    end

    test "when game doesn't exist" do
      with {:ok, socket} <- user_socket() do
        assert {:error, %{reason: "game not found"}} =
                 subscribe_and_join(socket, GameChannel, "game:flying-spaghetti-monster")
      end
    end
  end

  describe "handle event" do
    test "send event to game:xyz" do
      with game_name = FnChess.HaikuName.generate(),
           {:ok, game_name} = start_game(),
           {:ok, socket} = user_socket(),
           {:ok, _, socket} = subscribe_and_join(socket, GameChannel, "game:#{game_name}") do
        #
        event = %{"type" => "move", "origin" => "a2", "destination" => "a4"}
        ref = push(socket, "event", event)

        assert_broadcast("game_updated", %Game{events: [event]})
      end
    end
  end
end
