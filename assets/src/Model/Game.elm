module Model.Game exposing (..)

import List.Extra as List


type Player
    = White
    | Black


type Piece
    = Pawn
    | Rook
    | Knight
    | Bishop
    | Queen
    | King


type Square
    = Empty
    | Occupied Player Piece


type Location
    = Location Int Int


type alias Board =
    List Rank


type alias Rank =
    List Square


newGame : Board
newGame =
    List.transpose <|
        List.reverse <|
            [ [ Occupied Black Rook, Occupied Black Knight, Occupied Black Bishop, Occupied Black Queen, Occupied Black King, Occupied Black Bishop, Occupied Black Knight, Occupied Black Rook ]
            , [ Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn, Occupied Black Pawn ]
            , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
            , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
            , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
            , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
            , [ Occupied White Pawn, Occupied White Pawn, Occupied White Pawn, Occupied White Pawn, Occupied White Pawn, Occupied White Pawn, Occupied White Pawn, Occupied White Pawn ]
            , [ Occupied White Rook, Occupied White Knight, Occupied White Bishop, Occupied White Queen, Occupied White King, Occupied White Bishop, Occupied White Knight, Occupied White Rook ]
            ]


removePieceAt : Location -> Board -> Board
removePieceAt (Location rankIndex fileIndex) board =
    List.updateAt rankIndex
        (\rank ->
            List.updateAt fileIndex
                (\_ -> Empty)
                rank
        )
        board


placePieceAt : Location -> Player -> Piece -> Board -> Board
placePieceAt (Location rankIndex fileIndex) player piece board =
    List.updateAt rankIndex
        (\rank ->
            List.updateAt fileIndex
                (\_ -> Occupied player piece)
                rank
        )
        board


updateSquare : Location -> (Square -> Square) -> Board -> Board
updateSquare (Location rankIndex fileIndex) update board =
    List.updateAt rankIndex
        (\rank ->
            List.updateAt fileIndex
                update
                rank
        )
        board
