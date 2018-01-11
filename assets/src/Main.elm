module Main exposing (..)

import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src)
import List.Extra as List
import Svg exposing (svg, rect, Svg, g)
import Svg.Attributes exposing (width, height, rx, ry, viewBox, x, y)


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
        (List.indexedMap rankView model.board)


boardViewBox =
    [ 0, 0, boardSize, boardSize ]
        |> List.map toString
        |> String.join " "


rankView : Int -> Rank -> Svg Msg
rankView rankIndex rank =
    g [] (List.indexedMap (squareView rankIndex) rank)


squareView : Int -> Int -> Square -> Svg Msg
squareView rankIndex fileIndex square =
    rect
        [ x (toString <| rankIndex * squareSize)
        , y (toString <| fileIndex * squareSize)
        , width (toString squareSize)
        , height (toString squareSize)
        ]
        []


boardSize =
    600


squareSize =
    boardSize // 8



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
