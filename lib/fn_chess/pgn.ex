defmodule FnChess.Pgn do
  alias FnChess.Pgn.Parser
  import Algae

  defmodule Result do
    defsum do
      defdata(WhiteWon :: none())
      defdata(BlackWon :: none())
      defdata(Draw :: none())
    end
  end

  defdata Tags do
    event :: String.t()
    site :: String.t()
    date :: String.t()
    round :: String.t()
    white :: String.t()
    black :: String.t()
    result :: FnChess.Pgn.Result.t()
    other :: %{String.t() => String.t()}
  end

  defmodule File do
    defsum do
      defdata(A :: none())
      defdata(B :: none())
      defdata(C :: none())
      defdata(D :: none())
      defdata(E :: none())
      defdata(F :: none())
      defdata(G :: none())
      defdata(H :: none())
    end
  end

  defmodule Rank do
    defsum do
      defdata(First :: none())
      defdata(Second :: none())
      defdata(Third :: none())
      defdata(Fourth :: none())
      defdata(Fifth :: none())
      defdata(Sixth :: none())
      defdata(Seventh :: none())
      defdata(Eighth :: none())
    end
  end

  defdata Square do
    rank :: String.t() \\ nil
    file :: FnChess.Pgn.File.t() \\ nil
  end

  defmodule Piece do
    defsum do
      defdata(Rook :: none())
      defdata(Knight :: none())
      defdata(Bishop :: none())
      defdata(Queen :: none())
      defdata(King :: none())
      defdata(Pawn :: none())
    end
  end

  defmodule Move do
    defsum do
      defdata MovePiece do
        piece :: FnChess.Pgn.Piece.t()
        destination :: FnChess.Pgn.Square.t()
        source :: FnChess.Pgn.Square.t() \\ nil
        is_capture :: boolean()
      end

      defdata(QueensideCastle :: none())
      defdata(KingsideCastle :: none())
    end
  end

  defdata PlayerTurn do
    move :: FnChess.Pgn.Move.t()
    check :: boolean() \\ false
    comment :: String.t() \\ nil
  end

  defdata Turn do
    white :: FnChess.Pgn.PlayerTurn.t()
    black :: FnChess.Pgn.PlayerTurn.t()
  end

  defdata do
    tags :: FnChess.Pgn.Tags
    turns :: list(FnChess.Pgn.Turn)
  end

  def parse(pgn) do
    Parser.parse(pgn)
  end
end
