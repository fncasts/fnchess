module Model.GameTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Test exposing (..)
import Model.Game as Game exposing (Board, Player(..), Piece(..))
import Util exposing (unindent, (=>))
import Model.Location exposing (..)


suite : Test
suite =
    describe "Game"
        [ describe "Ascii"
            [ describe "fromAscii"
                [ test "parse starting position" <|
                    \_ ->
                        Expect.equal
                            (Game.fromAscii
                                """
                            r n b q k b n r
                            p p p p p p p p
                            - - - - - - - -
                            - - - - - - - -
                            - - - - - - - -
                            - - - - - - - -
                            P P P P P P P P
                            R N B Q K B N R
                            """
                            )
                            Game.newGame
                ]
            , describe "toAscii"
                [ test "starting position toAscii" <|
                    \_ ->
                        Expect.equal
                            (unindent
                                """
                            r n b q k b n r
                            p p p p p p p p
                            - - - - - - - -
                            - - - - - - - -
                            - - - - - - - -
                            - - - - - - - -
                            P P P P P P P P
                            R N B Q K B N R
                            """
                            )
                            (Game.toAscii <| Game.newGame)
                ]
            ]
        , test "removePieceAt" <|
            \_ ->
                expectBoard
                    (Game.removePieceAt e2 Game.newGame)
                    """
                    r n b q k b n r
                    p p p p p p p p
                    - - - - - - - -
                    - - - - - - - -
                    - - - - - - - -
                    - - - - - - - -
                    P P P P - P P P
                    R N B Q K B N R
                    """
        , test "placePieceAt" <|
            \_ ->
                expectBoard
                    (Game.placePieceAt White Knight e4 <| Game.emptyGame)
                    """
                    - - - - - - - -
                    - - - - - - - -
                    - - - - - - - -
                    - - - - - - - -
                    - - - - N - - -
                    - - - - - - - -
                    - - - - - - - -
                    - - - - - - - -
                    """
        , describe "move"
            [ test "advance pawn 2" <|
                \_ ->
                    expectBoard
                        (Game.move (e2 => e4) Game.newGame)
                        """
                        r n b q k b n r
                        p p p p p p p p
                        - - - - - - - -
                        - - - - - - - -
                        - - - - P - - -
                        - - - - - - - -
                        P P P P - P P P
                        R N B Q K B N R
                        """
            , test "apply advance pawn 1" <|
                \_ ->
                    expectBoard
                        (Game.newGame |> Game.move (e2 => e3))
                        """
                        r n b q k b n r
                        p p p p p p p p
                        - - - - - - - -
                        - - - - - - - -
                        - - - - - - - -
                        - - - - P - - -
                        P P P P - P P P
                        R N B Q K B N R
                        """
            ]
        ]


expectBoard : Board -> String -> Expect.Expectation
expectBoard actualGame expected =
    Expect.equal (Game.toAscii actualGame) (unindent expected)
