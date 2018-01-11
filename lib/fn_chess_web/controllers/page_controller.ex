defmodule FnChessWeb.PageController do
  use FnChessWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
