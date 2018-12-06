module Model.Game
    exposing
        ( Player(..)
        , Piece(..)
        , Square(..)
        , Board
        , Game
        , Event(..)
        , Board(..)
        , placePieceAt
        , removePieceAt
        , newGame
        , emptyGame
        , foldl
        , GameName
        , nameDecoder
        , gameNameToString
        , gameNameFromString
        , decoder
        , applyEvent
        , encodeEvent
        , fromAscii
        , toAscii
        , move
        )

import List.Extra as List
import Json.Decode as JD
import Json.Encode as JE
import Regex
import Util exposing (submatches, unindent)
import Model.Location as Location exposing (Location)


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


type alias RankIndex =
    Int


type alias FileIndex =
    Int


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


emptyGame : Board
emptyGame =
    Board
        [ [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
        , [ Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty ]
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
                        |> placePieceAt player piece destination


removePieceAt : Location -> Board -> Board
removePieceAt location board =
    updateSquare location (\_ -> Empty) board


placePieceAt : Player -> Piece -> Location -> Board -> Board
placePieceAt player piece location board =
    updateSquare location (\_ -> Occupied player piece) board


move : ( Location, Location ) -> Board -> Board
move ( origin, destination ) board =
    case squareAt origin board of
        Occupied player piece ->
            board
                |> removePieceAt origin
                |> placePieceAt player piece destination

        Empty ->
            board


squareAt : Location -> Board -> Square
squareAt location (Board ranks) =
    let
        ( rankIndex, fileIndex ) =
            Location.rankAndFileIndexes location
    in
        ranks
            |> List.getAt rankIndex
            |> Maybe.andThen (List.getAt fileIndex)
            |> Maybe.withDefault Empty


updateSquare : Location -> (Square -> Square) -> Board -> Board
updateSquare location update (Board board) =
    Board <|
        List.updateAt (Location.rankIndex location)
            (\rank ->
                List.updateAt (Location.fileIndex location) update rank
            )
            board


foldl : (Location -> Square -> a -> a) -> a -> Board -> a
foldl func acc board =
    List.foldl (\location acc -> func location (squareAt location board) acc) acc Location.all



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
                (JD.field "origin" Location.decoder)
                (JD.field "destination" Location.decoder)

        _ ->
            JD.fail "Invalid event"


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
                , ( "origin", Location.encode origin )
                , ( "destination", Location.encode destination )
                ]


toAscii : Board -> String
toAscii (Board ranks) =
    ranks
        |> List.transpose
        |> List.reverse
        |> List.map fileToAscii
        |> String.join "\n"


newline =
    String.fromList [ '\n' ]



-- ASCII ENCODING


fileToAscii : List Square -> String
fileToAscii squares =
    squares
        |> List.map squareToAscii
        |> String.join " "


squareToAscii : Square -> String
squareToAscii square =
    case square of
        Occupied White Rook ->
            "R"

        Occupied White King ->
            "K"

        Occupied White Queen ->
            "Q"

        Occupied White Bishop ->
            "B"

        Occupied White Pawn ->
            "P"

        Occupied White Knight ->
            "N"

        Occupied Black Rook ->
            "r"

        Occupied Black King ->
            "k"

        Occupied Black Queen ->
            "q"

        Occupied Black Bishop ->
            "b"

        Occupied Black Pawn ->
            "p"

        Occupied Black Knight ->
            "n"

        Empty ->
            "-"


fromAscii : String -> Board
fromAscii ascii =
    ascii
        |> unindent
        |> String.trim
        |> String.split "\n"
        |> List.map (String.trim >> parseFile)
        |> List.reverse
        |> List.transpose
        |> Board


parseFile : String -> List Square
parseFile asciiFile =
    asciiFile
        |> String.split " "
        |> List.map parseSquare


parseSquare : String -> Square
parseSquare squareAscii =
    case squareAscii of
        "R" ->
            Occupied White Rook

        "K" ->
            Occupied White King

        "Q" ->
            Occupied White Queen

        "B" ->
            Occupied White Bishop

        "P" ->
            Occupied White Pawn

        "N" ->
            Occupied White Knight

        "r" ->
            Occupied Black Rook

        "k" ->
            Occupied Black King

        "q" ->
            Occupied Black Queen

        "b" ->
            Occupied Black Bishop

        "p" ->
            Occupied Black Pawn

        "n" ->
            Occupied Black Knight

        "-" ->
            Empty

        square ->
            Util.todo <| "handle invalid square: " ++ square
