module Page.Game exposing (view, update, init, Msg, Model, subscriptions)

import Html exposing (Html, div, h1, img, button)
import Html.Attributes exposing (src)
import Html.Events exposing (onClick)
import List.Extra as List
import Svg exposing (svg, rect, Svg, g, text_, text)
import Svg.Attributes exposing (width, height, rx, ry, viewBox, x, y, fill, fontSize, style, transform, class)
import Svg.Events exposing (onMouseDown, onMouseUp, onMouseMove)
import Arithmetic exposing (isEven)
import Piece
import Mouse
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Uuid exposing (Uuid)
import Model.Game as Game exposing (Board, Player(..), Piece(..), Location, Square(..))


---- MODEL ----


type alias Model =
    { board : Board
    , drag : Maybe Drag
    , mousePosition : Mouse.Position
    , mouseMovementX : Int
    }


type Drag
    = Drag Location Player Piece


type alias MouseMove =
    { offsetX : Int
    , offsetY : Int
    , movementX : Int
    }


init : Uuid -> Model
init uuid =
    { board = Game.newGame
    , drag = Nothing
    , mousePosition = { x = 0, y = 0 }
    , mouseMovementX = 0
    }



---- UPDATE ----


type Msg
    = NoOp
    | DragStart Player Piece Location
    | DragEnd Location
    | MouseMoved MouseMove
    | DragReleasedOutsideBoard


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "Update" msg of
        NoOp ->
            ( model, Cmd.none )

        DragStart player piece location ->
            let
                updatedBoard =
                    Game.removePieceAt location model.board
            in
                ( { model
                    | board = updatedBoard
                    , drag = Just (Drag location player piece)
                  }
                , Cmd.none
                )

        DragReleasedOutsideBoard ->
            case model.drag of
                Just (Drag origin player piece) ->
                    let
                        updatedBoard =
                            Game.placePieceAt origin player piece model.board
                    in
                        ( { model | drag = Nothing, board = updatedBoard }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        DragEnd location ->
            case model.drag of
                Nothing ->
                    ( model, Cmd.none )

                Just (Drag origin player piece) ->
                    ( { model
                        | board = Game.placePieceAt location player piece model.board
                        , drag = Nothing
                      }
                    , Cmd.none
                    )

        MouseMoved { offsetX, offsetY, movementX } ->
            ( { model | mousePosition = { x = offsetX, y = offsetY }, mouseMovementX = movementX }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    svg
        [ width (toString boardSize)
        , height (toString boardSize)
        , viewBox boardViewBox
        ]
        [ boardView model.board
        , dragView model
        ]


boardView : Board -> Svg Msg
boardView board =
    g
        [ onMouseMove MouseMoved ]
        (Game.foldl squareView [] board)


onMouseMove : (MouseMove -> Msg) -> Svg.Attribute Msg
onMouseMove callback =
    Svg.Events.on "mousemove" (JD.map callback mouseMoveDecoder)


mouseMoveDecoder : JD.Decoder MouseMove
mouseMoveDecoder =
    JDP.decode MouseMove
        |> JDP.required "offsetX" JD.int
        |> JDP.required "offsetY" JD.int
        |> JDP.required "movementX" JD.int


dragView : Model -> Svg Msg
dragView { drag, mousePosition, mouseMovementX } =
    case drag of
        Nothing ->
            Svg.text ""

        Just (Drag origin player piece) ->
            let
                offset =
                    squareSize // 2

                rotation =
                    clamp -15 15 mouseMovementX
            in
                svg
                    [ x <| toString <| mousePosition.x - offset
                    , y <| toString <| mousePosition.y - offset
                    , height (toString squareSize)
                    , width (toString squareSize)
                    , style "pointer-events: none;"
                    ]
                    [ pieceView piece
                        player
                        [ transform <| "rotate(" ++ (toString rotation) ++ " 0 0)"
                        ]
                        (toFloat <| squareSize // 2)
                        (toFloat <| squareSize // 2)
                    ]


boardViewBox =
    [ 0, 0, boardSize, boardSize ]
        |> List.map toString
        |> String.join " "


squareView : Int -> Int -> Square -> List (Svg Msg) -> List (Svg Msg)
squareView rankIndex fileIndex square elements =
    elements
        ++ [ svg
                [ x (toString <| rankIndex * squareSize)
                , y (toString <| (7 - fileIndex) * squareSize)
                , width <| toString <| squareSize
                , height <| toString <| squareSize
                , onMouseUp (DragEnd (Game.Location rankIndex fileIndex))
                ]
                [ squareFillView rankIndex fileIndex square
                , coordinateAnnotationView rankIndex fileIndex
                , squarePieceView square (Game.Location rankIndex fileIndex)
                ]
           ]


squarePieceView square location =
    case square of
        Empty ->
            g [] []

        Occupied player piece ->
            pieceView piece player [ onMouseDown (DragStart player piece location) ] (toFloat <| squareSize // 2) (toFloat <| squareSize // 2)


pieceView : Piece -> Player -> (List (Svg.Attribute msg) -> Float -> Float -> Svg msg)
pieceView piece player attrs left top =
    g
        (attrs ++ [ class "piece" ])
        [ case piece of
            Pawn ->
                case player of
                    Black ->
                        Piece.blackPawn [] left top

                    White ->
                        Piece.whitePawn [] left top

            Bishop ->
                case player of
                    Black ->
                        Piece.blackBishop [] left top

                    White ->
                        Piece.whiteBishop [] left top

            Knight ->
                case player of
                    Black ->
                        Piece.blackKnight [] left top

                    White ->
                        Piece.whiteKnight [] left top

            King ->
                case player of
                    Black ->
                        Piece.blackKing [] left top

                    White ->
                        Piece.whiteKing [] left top

            Queen ->
                case player of
                    Black ->
                        Piece.blackQueen [] left top

                    White ->
                        Piece.whiteQueen [] left top

            Rook ->
                case player of
                    Black ->
                        Piece.blackRook [] left top

                    White ->
                        Piece.whiteRook [] left top
        ]


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
        , noTextSelect
        ]
        [ text (indexToRank rankIndex) ]


noTextSelect =
    style "user-select: none;"


coordsFontSize =
    14


numberView : Int -> Svg Msg
numberView fileIndex =
    text_
        [ fontSize <| toString <| coordsFontSize
        , x "5"
        , y "18"
        , noTextSelect
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



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Mouse.ups (\_ -> DragReleasedOutsideBoard)
