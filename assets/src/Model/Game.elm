module Model.Game exposing (Player(..), Piece(..), Location(..), Square(..), Board, placePieceAt, removePieceAt, newGame, foldl)

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


type Board
    = Board (List Rank)


type alias Rank =
    List Square


newGame : Board
newGame =
    Board <|
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
removePieceAt location board =
    updateSquare location (\_ -> Empty) board


placePieceAt : Location -> Player -> Piece -> Board -> Board
placePieceAt location player piece board =
    updateSquare location (\_ -> Occupied player piece) board


updateSquare : Location -> (Square -> Square) -> Board -> Board
updateSquare (Location rankIndex fileIndex) update (Board board) =
    Board <|
        List.updateAt rankIndex
            (\rank ->
                List.updateAt fileIndex
                    update
                    rank
            )
            board


foldl : (Int -> Int -> Square -> a -> a) -> a -> Board -> a
foldl func acc board =
    List.foldl
        (\( rankIndex, fileIndex, square ) acc ->
            func rankIndex fileIndex square acc
        )
        acc
        (indexedSquares board)


indexedSquares : Board -> List ( Int, Int, Square )
indexedSquares (Board ranks) =
    List.concat <|
        (List.indexedMap
            (\rankIndex rank ->
                (List.indexedMap
                    (\fileIndex square ->
                        ( rankIndex, fileIndex, square )
                    )
                    rank
                )
            )
            ranks
        )
