module Main exposing (..)

import Html exposing (Html, div, h1, img)
import Html.Attributes exposing (src)
import List.Extra as List
import Svg exposing (svg, rect, Svg, g, text_, text)
import Svg.Attributes exposing (width, height, rx, ry, viewBox, x, y, fill, fontSize)
import Arithmetic exposing (isEven)
import Piece


---- MODEL ----


type alias Model =
    { board : Board
    }


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


type alias Board =
    List Rank


type alias Rank =
    List Square


init : ( Model, Cmd Msg )
init =
    ( { board = newGame }, Cmd.none )


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



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    svg
        [ width (toString boardSize), height (toString boardSize), viewBox boardViewBox ]
        (List.indexedMap rankView (Debug.log "board" model.board))


boardViewBox =
    [ 0, 0, boardSize, boardSize ]
        |> List.map toString
        |> String.join " "


rankView : Int -> Rank -> Svg Msg
rankView rankIndex rank =
    g [] (List.indexedMap (squareView rankIndex) rank)


squareView : Int -> Int -> Square -> Svg Msg
squareView rankIndex fileIndex square =
    svg
        [ x (toString <| rankIndex * squareSize)
        , y (toString <| (7 - fileIndex) * squareSize)
        , width <| toString <| squareSize
        , height <| toString <| squareSize
        ]
        [ squareFillView rankIndex fileIndex square
        , coordinateAnnotationView rankIndex fileIndex
        , squarePieceView square
        ]


squarePieceView square =
    case square of
        Empty ->
            g [] []

        Occupied player piece ->
            pieceView piece player [] (toFloat <| squareSize // 2) (toFloat <| squareSize // 2)


pieceView : Piece -> Player -> (List (Svg.Attribute msg) -> Float -> Float -> Svg msg)
pieceView piece player attrs left top =
    case piece of
        Pawn ->
            case player of
                Black ->
                    Piece.blackPawn attrs left top

                White ->
                    Piece.whitePawn attrs left top

        Bishop ->
            case player of
                Black ->
                    Piece.blackBishop attrs left top

                White ->
                    Piece.whiteBishop attrs left top

        Knight ->
            case player of
                Black ->
                    Piece.blackKnight attrs left top

                White ->
                    Piece.whiteKnight attrs left top

        King ->
            case player of
                Black ->
                    Piece.blackKing attrs left top

                White ->
                    Piece.whiteKing attrs left top

        Queen ->
            case player of
                Black ->
                    Piece.blackQueen attrs left top

                White ->
                    Piece.whiteQueen attrs left top

        Rook ->
            case player of
                Black ->
                    Piece.blackRook attrs left top

                White ->
                    Piece.whiteRook attrs left top


squareFillView : Int -> Int -> Square -> Svg Msg
squareFillView rankIndex fileIndex square =
    rect
        [ width (toString squareSize)
        , height (toString squareSize)
        , fill <| squareColor rankIndex fileIndex
        ]
        []


squareColor : Int -> Int -> String
squareColor rankIndex fileIndex =
    if isEven (rankIndex + fileIndex) then
        "#f2efc7"
    else
        "#d2bba0"


coordinateAnnotationView : Int -> Int -> Svg Msg
coordinateAnnotationView rankIndex fileIndex =
    g [] <|
        List.filterMap identity <|
            [ if fileIndex == 0 then
                Just <| letterView rankIndex
              else
                Nothing
            , if rankIndex == 0 then
                Just <| numberView fileIndex
              else
                Nothing
            ]


letterView : Int -> Svg Msg
letterView rankIndex =
    text_
        [ fontSize <| toString <| coordsFontSize
        , x <| toString <| (squareSize - coordsFontSize)
        , y <| toString <| (8 + squareSize - coordsFontSize)
        ]
        [ text (indexToRank rankIndex) ]


coordsFontSize =
    14


numberView : Int -> Svg Msg
numberView fileIndex =
    text_
        [ fontSize <| toString <| coordsFontSize
        , x "5"
        , y "18"
        ]
        [ text <| toString <| fileIndex + 1 ]


boardSize =
    600


squareSize =
    boardSize // 8


indexToRank index =
    [ "a", "b", "c", "d", "e", "f", "g", "h" ]
        |> List.getAt index
        |> Maybe.withDefault ""



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
