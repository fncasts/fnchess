defmodule FnChess.Game do
  alias FnChess.Event
  alias __MODULE__
  import Algae

  @type event() :: any()

  defdata do
    events :: list(event())
  end

  @spec new() :: Game.t()
  def new() do
    %Game{events: []}
  end

  @spec update(Game.t(), event()) :: {:ok, Game.t()}
  def update(game = %Game{}, event) do
    {:ok, %Game{game | events: game.events ++ [event]}}
  end

  @spec events(Game.t()) :: list(event())
  def events(game = %Game{events: events}), do: events
end
