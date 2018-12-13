defmodule FnChess.GameServer do
  use GenServer
  alias FnChess.Game
  #### API ####

  @spec start_link(String.t()) :: {:ok, pid()} | {:error, any()}
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: via_tuple(name))
  end

  @spec update(String.t(), Game.event()) :: {:ok, Game.t()} | {:error, any()}
  def update(name, event) do
    GenServer.call(via_tuple(name), {:update, event})
  end

  @spec fetch(String.t()) :: {:ok, Game.t()} | {:error, any()}
  def fetch(name) do
    case Registry.lookup(FnChess.GameRegistry, name) do
      [] ->
        {:error, :not_found}

      _ ->
        GenServer.call(via_tuple(name), :fetch)
    end
  end

  #### SERVER CALLBACKS ####

  @spec init(any()) :: {:ok, Game.t()}
  def init(_) do
    {:ok, Game.new()}
  end

  @spec handle_call({:update, Game.event()}, GenServer.from(), Game.t()) ::
          {:reply, {:ok, Game.t()}, Game.t()}
          | {:reply, {:error, String.t()}, Game.t()}
  def handle_call({:update, event}, _from, game) do
    {:ok, updated_game} = Game.update(game, event)
    {:reply, {:ok, updated_game}, updated_game}
  end

  @spec handle_call(:fetch, GenServer.from(), Game.t()) :: {:reply, {:ok, Game.t()}, Game.t()}
  def handle_call(:fetch, _from, game) do
    {:reply, {:ok, game}, game}
  end

  #### HELPERS ####

  @spec via_tuple(String.t()) :: {:via, atom(), any()}
  def via_tuple(name) do
    {:via, Registry, {FnChess.GameRegistry, name}}
  end

  @spec game_pid(String.t()) :: pid() | nil
  def game_pid(name) when is_binary(name) do
    GenServer.whereis(via_tuple(name))
  end
end
