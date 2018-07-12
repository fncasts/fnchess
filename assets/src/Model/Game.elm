module Model.Game
    exposing
        ( Player(..)
        , Piece(..)
        , Location(..)
        , Square(..)
        , Board
        , Game
        , Event(..)
        , placePieceAt
        , removePieceAt
        , newGame
        , foldl
        , GameName
        , nameDecoder
        , gameNameToString
        , gameNameFromString
        , decoder
        , applyEvent
        , encodeEvent
        )

import List.Extra as List
import Json.Decode as JD
import Json.Encode as JE


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


type alias Game =
    { events : List Event
    }


type Event
    = Move Location Location


type GameName
    = GameName String


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


applyEvent : Event -> Board -> Board
applyEvent event board =
    case event of
        Move origin destination ->
            case squareAt origin board of
                Empty ->
                    board

                Occupied player piece ->
                    board
                        |> removePieceAt origin
                        |> placePieceAt destination player piece


squareAt : Location -> Board -> Square
squareAt (Location rankIndex fileIndex) (Board ranks) =
    let
        maybeSquare =
            List.getAt rankIndex ranks
                |> Maybe.andThen (\rank -> List.getAt fileIndex rank)
    in
        case maybeSquare of
            Just square ->
                square

            Nothing ->
                Debug.crash "invalid location - should be impossible..."


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



-- DECODERS


decoder : JD.Decoder Game
decoder =
    JD.map Game
        (JD.field "events" (JD.list eventDecoder))


eventDecoder : JD.Decoder Event
eventDecoder =
    JD.field "type" JD.string
        |> JD.andThen eventDecoderHelp


eventDecoderHelp : String -> JD.Decoder Event
eventDecoderHelp type_ =
    case type_ of
        "move" ->
            JD.map2 Move
                (JD.field "origin" locationDecoder)
                (JD.field "destination" locationDecoder)

        _ ->
            JD.fail "Invalid event"


locationDecoder : JD.Decoder Location
locationDecoder =
    JD.map2 Location
        (JD.field "rank" JD.int)
        (JD.field "file" JD.int)


nameDecoder : JD.Decoder GameName
nameDecoder =
    JD.string
        |> JD.map GameName


gameNameToString : GameName -> String
gameNameToString (GameName name) =
    name


gameNameFromString : String -> GameName
gameNameFromString name =
    GameName name



-- ENCODERS


encodeEvent : Event -> JE.Value
encodeEvent event =
    case event of
        Move origin destination ->
            JE.object
                [ ( "type", JE.string "move" )
                , ( "origin", encodeLocation origin )
                , ( "destination", encodeLocation destination )
                ]


encodeLocation : Location -> JE.Value
encodeLocation (Location rankIndex fileIndex) =
    JE.object
        [ ( "rank", JE.int rankIndex )
        , ( "file", JE.int fileIndex )
        ]
