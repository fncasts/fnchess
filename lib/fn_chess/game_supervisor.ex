defmodule FnChess.GameSupervisor do
  use DynamicSupervisor

  alias FnChess.GameServer

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a `GameServer` process and supervises it.
  """
  def start_game(name) do
    child_spec = %{
      id: GameServer,
      start: {GameServer, :start_link, [name]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminates the `GameServer` process normally. It won't be restarted.
  """
  def stop_game(name) do
    child_pid = GameServer.game_pid(name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
