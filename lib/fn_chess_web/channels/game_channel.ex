defmodule FnChessWeb.GameChannel do
  use FnChessWeb, :channel

  alias FnChess.GameServer

  def join("game:" <> name, payload, socket) do
    case GameServer.fetch(name) do
      {:ok, game} ->
        {:ok, game, socket |> assign(:game_name, name)}

      {:error, :not_found} ->
        {:error, %{reason: "game not found"}}
    end
  end

  def handle_in("event", event, socket) do
    case GameServer.update(socket.assigns.game_name, event) do
      {:ok, updated_game} ->
        :ok = broadcast(socket, "game_updated", updated_game)
        {:reply, :ok, socket}

      {:error, description} ->
        {:reply, {:error, description}, socket}
    end
  end
end
