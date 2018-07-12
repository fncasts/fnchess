defmodule FnChessWeb.GameChannelTest do
  use FnChessWeb.ChannelCase

  alias FnChess.Game
  alias FnChess.GameServer
  alias FnChess.GameSupervisor
  alias FnChessWeb.GameChannel
  alias FnChessWeb.GamesChannel
  alias FnChessWeb.UserSocket

  setup do
    game_id = Ecto.UUID.generate()
    topic = "games:lobby"
    user_id = "jimbo"

    game_name = "abc123"
    {:ok, game_pid} = GameSupervisor.start_game(game_name)

    {:ok, socket} = connect(UserSocket, %{"user_id" => user_id})
    {:ok, _, socket} = subscribe_and_join(socket, GameChannel, "game:#{game_name}")
    {:ok, socket: socket}
  end

  test "send event to game:xyz", %{socket: socket} do
    event = %{"type" => "move", "origin" => "a2", "destination" => "a4"}
    ref = push(socket, "event", event)

    assert_broadcast("game_updated", %Game{events: [event]})
  end
end
