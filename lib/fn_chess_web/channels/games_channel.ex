defmodule FnChessWeb.GamesChannel do
  use FnChessWeb, :channel

  alias FnChess.GameSupervisor

  def join("games:lobby", payload, socket) do
    {:ok, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  def handle_in("create_game", payload, socket) do
    name = FnChess.HaikuName.generate()

    case GameSupervisor.start_game(name) do
      {:ok, game_pid} ->
        :ok = broadcast(socket, "game_created", %{name: name})
        {:reply, {:ok, %{name: name}}, socket}

      {:error, description} ->
        {:reply, {:error, description}, socket}
    end
  end
end
