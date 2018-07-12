defmodule FnChessWeb.GamesChannelTest do
  use FnChessWeb.ChannelCase

  alias FnChessWeb.GamesChannel
  alias FnChessWeb.UserSocket
  alias FnChess.Game
  alias FnChess.GameServer

  setup do
    game_id = Ecto.UUID.generate()
    topic = "games:lobby"
    user_id = "jimbo"

    {:ok, socket} = connect(UserSocket, %{"user_id" => user_id})
    {:ok, _, socket} = subscribe_and_join(socket, GamesChannel, "games:lobby")
    {:ok, socket: socket}
  end

  test "create game", %{socket: socket} do
    ref = push(socket, "create_game", %{})
    assert_reply(ref, :ok, payload, 200)

    assert %{name: name} = payload

    assert Process.alive?(GameServer.game_pid(name))
  end
end
