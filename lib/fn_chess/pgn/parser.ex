defmodule FnChess.Pgn.Parser do
  alias FnChess.Pgn
  alias FnChess.Pgn.Parser
  alias FnChess.Pgn.Tags
  alias FnChess.Pgn.Turn
  alias FnChess.Pgn.Move
  alias FnChess.Pgn.PlayerTurn
  alias FnChess.Pgn.Square
  alias FnChess.Pgn.Piece
  alias FnChess.Pgn.Source
  alias FnChess.Pgn.Result
  use Combine
  import FnChess.Pgn.Parser.Util

  @known_tags [
    "Event",
    "Site",
    "Date",
    "Round",
    "White",
    "Black",
    "Result"
  ]

  @capture "x"
  @check "+"

  def parse(png) do
    case Combine.parse(png, parser()) do
      [pgn = %Pgn{}] -> pgn
      error -> raise "Parse error #{inspect(error)}"
    end
  end

  defp parser, do: pgn()

  defparser(:pgn) do
    sequence([tags(), ignore(many(newline())), turns(), result()])
    |> map(fn [tags_, turns_, result_] ->
      %Pgn{tags: tags_, turns: turns_}
    end)
  end

  defparser(:tags) do
    sep_by(tag(), ignore(newline()))
    |> map(&to_tags_struct/1)
  end

  defparser(:result) do
    choice_from_map(%{
      "1-0" => %Result.WhiteWon{},
      "0-1" => %Result.BlackWon{},
      "1/2-1/2" => %Result.Draw{}
    })
  end

  defp to_tags_struct(tags) do
    {known, other} =
      tags
      |> Enum.into(%{})
      |> Map.split(@known_tags)

    prepared_known =
      known
      |> map_keys(&(&1 |> String.downcase() |> String.to_atom()))

    prepared = Map.put(prepared_known, :other, other)

    struct(Tags, prepared)
  end

  defparser(:tag) do
    between(char("["), tag_key_value(), char("]"))
  end

  defparser(:tag_key_value) do
    choice([
      sequence([string("Result"), ignore(space()), between(char("\""), result(), char("\""))]),
      sequence([tag_name(), ignore(space()), tag_value()])
    ])
    |> map(fn [k, v] -> {k, v} end)
  end

  defparser(:tag_name) do
    word()
  end

  defparser(:tag_value) do
    quoted_string()
  end

  defparser(:turns) do
    sep_by(turn(), ignore(choice([space(), newline()])))
  end

  defparser(:turn) do
    sequence([
      move_number(),
      ignore(choice([space(), newline()])),
      player_turn(),
      ignore(whitespace()),
      option(player_turn())
    ])
    |> map(fn [index, white, black] ->
      %Turn{white: white, black: black}
    end)
  end

  defparser(:move_number) do
    sequence([integer(), ignore(string("."))])
    |> map(fn [n] -> n end)
  end

  defparser(:player_turn) do
    sequence([move(), has_string(@check), comment()])
    |> map(fn [move_, check_, comment_] ->
      %PlayerTurn{move: move_, check: check_, comment: comment_}
    end)
  end

  defparser(:move) do
    choice([
      queenside_castle(),
      kingside_castle(),
      move_piece()
    ])
  end

  defparser(:queenside_castle) do
    map(string("O-O-O"), fn _ -> %Move.QueensideCastle{} end)
  end

  defparser(:kingside_castle) do
    map(string("O-O"), fn _ -> %Move.KingsideCastle{} end)
  end

  defparser(:move_piece) do
    map(
      sequence([
        option(piece()),
        option(square() |> followed_by(either(square(), string(@capture)))),
        has_string(@capture),
        square()
      ]),
      fn [piece_, source_, capture_, destination_] ->
        %Move.MovePiece{
          piece: piece_ || Piece.Pawn,
          source: source_,
          destination: destination_,
          is_capture: capture_
        }
      end
    )
  end

  defparser(:file) do
    choice_from_map(%{
      "a" => File.A,
      "b" => File.B,
      "c" => File.C,
      "d" => File.D,
      "e" => File.E,
      "f" => File.F,
      "g" => File.G,
      "h" => File.H
    })
  end

  defparser(:rank) do
    choice_from_map(%{
      "1" => Rank.First,
      "2" => Rank.Second,
      "3" => Rank.Third,
      "4" => Rank.Fourth,
      "5" => Rank.Fifth,
      "6" => Rank.Sixth,
      "7" => Rank.Seventh,
      "8" => Rank.Eigth
    })
  end

  defparser(:piece) do
    choice_from_map(%{
      "R" => Piece.Rook,
      "B" => Piece.Bishop,
      "K" => Piece.King,
      "Q" => Piece.Queen,
      "N" => Piece.Knight
    })
  end

  defparser(:square) do
    sequence([file(), option(rank())])
    |> map(fn [file_, rank_] ->
      %Square{rank: rank_, file: file_}
    end)
  end

  defparser(:comment) do
    option(
      skip(space())
      |> between(char("{"), words() |> map(fn words_ -> Enum.join(words_, "") end), char("}"))
    )
  end
end
