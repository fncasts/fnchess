defmodule FnChess.Pgn.ParserTest do
  use ExUnit.Case, async: true
  alias FnChess.Pgn
  alias FnChess.Pgn.Parser
  alias FnChess.Pgn.Tags
  alias FnChess.Pgn.Turn
  alias FnChess.Pgn.PlayerTurn
  alias FnChess.Pgn.Move
  alias FnChess.Pgn.Movement
  alias FnChess.Pgn.Square
  alias FnChess.Pgn.Piece
  alias FnChess.Pgn.Source
  alias FnChess.Pgn.Result

  @tags """
  [Event "F/S Return Match"]
  [Site "Belgrade, Serbia JUG"]
  [Date "1992.11.04"]
  [Round "29"]
  [White "Fischer, Robert J."]
  [Black "Spassky, Boris V."]
  [Result "1/2-1/2"]
  [Hotness "high"]
  """

  @moves """
  1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 {This opening is called the Ruy Lopez}
  4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7
  11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15. Nb1 h6 16. Bh4 c5 17. dxe5
  Nxe4 18. Bxe7 Qxe7 19. exd6 Qf6 20. Nbd2 Nxd6 21. Nc4 Nxc4 22. Bxc4 Nb6
  23. Ne5 Rae8 24. Bxf7+ Rxf7 25. Nxf7 Rxe1+ 26. Qxe1 Kxf7 27. Qe3 Qg5 28. Qxg5
  hxg5 29. b3 Ke6 30. a3 Kd6 31. axb4 cxb4 32. Ra5 Nd5 33. f3 Bc8 34. Kf2 Bf5
  35. Ra7 g6 36. Ra6+ Kc5 37. Ke1 Nf4 38. g3 Nxh3 39. Kd2 Kb5 40. Rd6 Kc5 41. Ra6
  Nf2 42. g4 Bd3 43. Re6 1/2-1/2
  """

  @pgn """
  #{@tags}


  #{@moves}
  """

  test "piece parser" do
    assert Combine.parse("R", Parser.piece()) == [Piece.Rook]
    assert Combine.parse("B", Parser.piece()) == [Piece.Bishop]
    assert Combine.parse("K", Parser.piece()) == [Piece.King]
    assert Combine.parse("Q", Parser.piece()) == [Piece.Queen]
    assert Combine.parse("N", Parser.piece()) == [Piece.Knight]
  end

  test "rank parser" do
    assert Combine.parse("1", Parser.rank()) == [Rank.First]
    assert Combine.parse("2", Parser.rank()) == [Rank.Second]
    assert Combine.parse("3", Parser.rank()) == [Rank.Third]
    assert Combine.parse("4", Parser.rank()) == [Rank.Fourth]
    assert Combine.parse("5", Parser.rank()) == [Rank.Fifth]
    assert Combine.parse("6", Parser.rank()) == [Rank.Sixth]
    assert Combine.parse("7", Parser.rank()) == [Rank.Seventh]
    assert Combine.parse("8", Parser.rank()) == [Rank.Eigth]
  end

  test "file parser" do
    assert Combine.parse("a", Parser.file()) == [File.A]
    assert Combine.parse("b", Parser.file()) == [File.B]
    assert Combine.parse("c", Parser.file()) == [File.C]
    assert Combine.parse("d", Parser.file()) == [File.D]
    assert Combine.parse("e", Parser.file()) == [File.E]
    assert Combine.parse("f", Parser.file()) == [File.F]
    assert Combine.parse("g", Parser.file()) == [File.G]
    assert Combine.parse("h", Parser.file()) == [File.H]
  end

  test "tags parser" do
    assert Combine.parse(@tags, Parser.tags()) == [
             %FnChess.Pgn.Tags{
               black: "Spassky, Boris V.",
               date: "1992.11.04",
               event: "F/S Return Match",
               other: %{"Hotness" => "high"},
               result: %Result.Draw{},
               round: "29",
               site: "Belgrade, Serbia JUG",
               white: "Fischer, Robert J."
             }
           ]
  end

  describe "player_turn parser" do
    test "defaults to pawn when piece is not specified" do
      assert parse_player_turn("e4") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Pawn,
                 destination: %Square{file: File.E, rank: Rank.Fourth}
               }
             }
    end

    test "with piece specified" do
      assert parse_player_turn("Nf3") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Knight,
                 destination: %Square{file: File.F, rank: Rank.Third}
               }
             }
    end

    test "with source file specified" do
      assert parse_player_turn("Nbd7") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Knight,
                 source: %Square{file: File.B},
                 destination: %Square{file: File.D, rank: Rank.Seventh}
               }
             }
    end

    test "queenside castle" do
      assert parse_player_turn("O-O-O") == %PlayerTurn{
               move: %Move.QueensideCastle{},
               check: false
             }
    end

    test "kingside castle" do
      assert parse_player_turn("O-O") == %PlayerTurn{move: %Move.KingsideCastle{}, check: false}
    end

    test "check" do
      assert parse_player_turn("Nbd7+") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Knight,
                 source: %Square{file: File.B},
                 destination: %Square{file: File.D, rank: Rank.Seventh}
               },
               check: true
             }
    end

    test "comment" do
      assert parse_player_turn("a6 {This opening is called the Ruy Lopez}") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Pawn,
                 destination: %Square{rank: Rank.Sixth, file: File.A}
               },
               comment: "This opening is called the Ruy Lopez"
             }
    end

    test "capture with no piece specified" do
      assert parse_player_turn("dxe5") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Pawn,
                 source: %Square{file: File.D},
                 destination: %Square{rank: Rank.Fifth, file: File.E},
                 is_capture: true
               }
             }
    end

    test "capture with piece specified" do
      assert parse_player_turn("Nxe4") == %PlayerTurn{
               move: %Move.MovePiece{
                 piece: Piece.Knight,
                 destination: %Square{rank: Rank.Fourth, file: File.E},
                 is_capture: true
               }
             }
    end

    def parse_player_turn(pgn_representation) do
      case Combine.parse(pgn_representation, Parser.player_turn()) do
        [success_result] -> success_result
        fail_result -> fail_result
      end
    end
  end

  test "parse turn" do
    assert Combine.parse("17. dxe5 Nxe4", Parser.turn()) ==
             [
               %Turn{
                 black: %PlayerTurn{
                   check: false,
                   comment: nil,
                   move: %Move.MovePiece{
                     destination: %Square{file: File.E, rank: Rank.Fourth},
                     is_capture: true,
                     piece: Piece.Knight,
                     source: nil
                   }
                 },
                 white: %PlayerTurn{
                   check: false,
                   comment: nil,
                   move: %Move.MovePiece{
                     destination: %Square{file: File.E, rank: Rank.Fifth},
                     is_capture: true,
                     piece: Piece.Pawn,
                     source: %Square{file: File.D, rank: nil}
                   }
                 }
               }
             ]
  end

  test "parse turn with newline" do
    assert Combine.parse(
             """
             17. dxe5
             Nxe4
             """,
             Parser.turn()
           ) ==
             [
               %Turn{
                 black: %PlayerTurn{
                   check: false,
                   comment: nil,
                   move: %Move.MovePiece{
                     destination: %Square{file: File.E, rank: Rank.Fourth},
                     is_capture: true,
                     piece: Piece.Knight,
                     source: nil
                   }
                 },
                 white: %PlayerTurn{
                   check: false,
                   comment: nil,
                   move: %Move.MovePiece{
                     destination: %Square{file: File.E, rank: Rank.Fifth},
                     is_capture: true,
                     piece: Piece.Pawn,
                     source: %Square{file: File.D, rank: nil}
                   }
                 }
               }
             ]
  end

  test "parse pgn" do
    parsed = Parser.parse(@pgn)

    expected_pgn = %Pgn{
      tags: %Tags{
        event: "F/S Return Match",
        site: "Belgrade, Serbia JUG",
        date: "1992.11.04",
        round: "29",
        white: "Fischer, Robert J.",
        black: "Spassky, Boris V.",
        result: %FnChess.Pgn.Result.Draw{},
        other: %{"Hotness" => "high"}
      },
      turns: [
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: "This opening is called the Ruy Lopez",
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.KingsideCastle{}
          },
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Seventh},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.First},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.KingsideCastle{}
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Eigth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.H, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Seventh},
              is_capture: false,
              piece: Piece.Knight,
              source: %Square{file: File.B, rank: nil}
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fifth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.A, rank: nil}
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fifth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.C, rank: nil}
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Seventh},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.H, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.First},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.H, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Fifth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.D, rank: nil}
            }
          },
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Fourth},
              is_capture: true,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.Queen,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Sixth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.E, rank: nil}
            }
          },
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Queen,
              source: nil
            }
          }
        },
        %Turn{
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Second},
              is_capture: false,
              piece: Piece.Knight,
              source: %Square{file: File.B, rank: nil}
            }
          },
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Sixth},
              is_capture: true,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fourth},
              is_capture: true,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fourth},
              is_capture: true,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Eigth},
              is_capture: false,
              piece: Piece.Rook,
              source: %Square{file: File.A, rank: nil}
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.Rook,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: true,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.Bishop,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: true,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.First},
              is_capture: true,
              piece: Piece.Rook,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.Knight,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Seventh},
              is_capture: true,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.First},
              is_capture: true,
              piece: Piece.Queen,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Queen,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Queen,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Fifth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.H, rank: nil}
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Fifth},
              is_capture: true,
              piece: Piece.Queen,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fourth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.C, rank: nil}
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fourth},
              is_capture: true,
              piece: Piece.Pawn,
              source: %Square{file: File.A, rank: nil}
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Eigth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Second},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Seventh},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: true,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.First},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.H, rank: Rank.Third},
              is_capture: true,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.B, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Second},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.C, rank: Rank.Fifth},
              is_capture: false,
              piece: Piece.King,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.F, rank: Rank.Second},
              is_capture: false,
              piece: Piece.Knight,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.A, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        },
        %Turn{
          black: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.D, rank: Rank.Third},
              is_capture: false,
              piece: Piece.Bishop,
              source: nil
            }
          },
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.G, rank: Rank.Fourth},
              is_capture: false,
              piece: Piece.Pawn,
              source: nil
            }
          }
        },
        %Turn{
          black: nil,
          white: %PlayerTurn{
            check: false,
            comment: nil,
            move: %Move.MovePiece{
              destination: %Square{file: File.E, rank: Rank.Sixth},
              is_capture: false,
              piece: Piece.Rook,
              source: nil
            }
          }
        }
      ]
    }

    assert parsed == expected_pgn
  end
end
