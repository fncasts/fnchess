module Model.GameTest exposing (suite)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, list, int, string)
import Test exposing (..)
import Model.Game as Game
import Util exposing (unindent)


suite : Test
suite =
    describe "Ascii"
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
