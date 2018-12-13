module Page.Game exposing (Model, Msg, init, subscriptions, update, view)

import Arithmetic exposing (isEven)
import Html exposing (Html, button, div, h1, img)
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import List.Extra as List
import Model.Game as Game exposing (Board, Game, Piece(..), Player(..), Square(..))
import Model.Location as Location exposing (Location)
import Mouse
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push exposing (Push)
import Phoenix.Socket as Socket exposing (Socket)
import Piece
import Svg exposing (Svg, g, rect, svg, text, text_)
import Svg.Attributes exposing (class, fill, fontSize, height, rx, ry, style, transform, viewBox, width, x, y)
import Svg.Events exposing (onMouseDown, onMouseMove, onMouseUp)



---- MODEL ----


type Model
    = Loading Game.GameName
    | Loaded LoadedModel
    | Error


type alias LoadedModel =
    { gameName : Game.GameName
    , board : Board
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


init : Game.GameName -> Model
init gameName =
    Loading gameName


initLoaded : Game.GameName -> Game -> Model
initLoaded gameName game =
    Loaded
        { gameName = gameName
        , board = gameToBoard game
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
    | GameUpdated (Result String Game)
    | JoinSucceeded (Result String Game)
    | JoinFailed


type alias UpdateConfig =
    { socketUrl : String
    }


update : UpdateConfig -> Msg -> Model -> ( Model, Cmd Msg )
update { socketUrl } msg model =
    case ( msg, model ) of
        ( JoinSucceeded gameResult, Loading gameName ) ->
            case gameResult of
                Ok game ->
                    ( initLoaded gameName game, Cmd.none )

                Err message ->
                    ( Error, Cmd.none )

        ( JoinFailed, _ ) ->
            ( Error, Cmd.none )

        ( DragStart player piece location, Loaded model ) ->
            let
                updatedBoard =
                    Game.removePieceAt location model.board
            in
            ( Loaded
                { model
                    | board = updatedBoard
                    , drag = Just (Drag location player piece)
                }
            , Cmd.none
            )

        ( DragReleasedOutsideBoard, Loaded model ) ->
            case model.drag of
                Just (Drag origin player piece) ->
                    let
                        updatedBoard =
                            Game.placePieceAt player piece origin model.board
                    in
                    ( Loaded { model | drag = Nothing, board = updatedBoard }, Cmd.none )

                Nothing ->
                    ( Loaded model, Cmd.none )

        ( DragEnd destination, Loaded model ) ->
            case model.drag of
                Nothing ->
                    ( Loaded model, Cmd.none )

                Just (Drag origin player piece) ->
                    ( Loaded
                        { model
                            | board = Game.placePieceAt player piece destination model.board
                            , drag = Nothing
                        }
                    , Phoenix.push socketUrl (pushEvent (Game.Move origin destination) model)
                    )

        ( MouseMoved { offsetX, offsetY, movementX }, Loaded model ) ->
            ( Loaded { model | mousePosition = { x = offsetX, y = offsetY }, mouseMovementX = movementX }
            , Cmd.none
            )

        ( GameUpdated gameResult, Loaded model ) ->
            case gameResult of
                Ok game ->
                    ( Loaded { model | board = gameToBoard game }, Cmd.none )

                Err message ->
                    ( Error, Cmd.none )

        _ ->
            ( model, Cmd.none )


gameToBoard : Game -> Board
gameToBoard game =
    List.foldl Game.applyEvent Game.newGame game.events


pushEvent : Game.Event -> LoadedModel -> Push Msg
pushEvent event loadedModel =
    Push.init (gameChannelName loadedModel.gameName) "event"
        |> Push.withPayload (Game.encodeEvent event)



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        Loading gameName ->
            text "loading"

        Loaded model ->
            svg
                [ width (toString boardSize)
                , height (toString boardSize)
                , viewBox boardViewBox
                ]
                [ boardView model.board
                , dragView model
                ]

        Error ->
            text "error"


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


dragView : LoadedModel -> Svg Msg
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
                    [ transform <| "rotate(" ++ toString rotation ++ " 0 0)"
                    ]
                    (toFloat <| squareSize // 2)
                    (toFloat <| squareSize // 2)
                ]


boardViewBox =
    [ 0, 0, boardSize, boardSize ]
        |> List.map toString
        |> String.join " "


squareView : Location -> Square -> List (Svg Msg) -> List (Svg Msg)
squareView location square elements =
    elements
        ++ [ svg
                [ x (toString <| Location.rankIndex location * squareSize)
                , y (toString <| (7 - Location.fileIndex location) * squareSize)
                , width <| toString <| squareSize
                , height <| toString <| squareSize
                , onMouseUp (DragEnd location)
                ]
                [ squareFillView location square
                , coordinateAnnotationView location
                , squarePieceView square location
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


squareFillView : Location -> Square -> Svg Msg
squareFillView location square =
    rect
        [ width (toString squareSize)
        , height (toString squareSize)
        , fill <| squareColor location
        ]
        []


squareColor : Location -> String
squareColor location =
    if isEven (Location.rankIndex location + Location.fileIndex location) then
        "#f2efc7"

    else
        "#d2bba0"


coordinateAnnotationView : Location -> Svg Msg
coordinateAnnotationView location =
    let
        fileIndex =
            Location.fileIndex location

        rankIndex =
            Location.rankIndex location
    in
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


subscriptions : String -> Model -> Sub Msg
subscriptions socketUrl model =
    Sub.batch
        [ Mouse.ups (\_ -> DragReleasedOutsideBoard)
        , case model of
            Loading gameName ->
                Phoenix.connect
                    (Socket.init socketUrl)
                    [ gameChannel gameName ]

            Loaded { gameName } ->
                Phoenix.connect
                    (Socket.init socketUrl)
                    [ gameChannel gameName ]

            Error ->
                Sub.none
        ]


gameChannel : Game.GameName -> Channel Msg
gameChannel gameName =
    Channel.init (gameChannelName gameName)
        |> Channel.onJoin (JD.decodeValue Game.decoder >> JoinSucceeded)
        |> Channel.onJoinError (\_ -> JoinFailed)
        |> Channel.on "game_updated" (JD.decodeValue Game.decoder >> GameUpdated)


gameChannelName : Game.GameName -> String
gameChannelName gameName =
    "game:" ++ Game.gameNameToString gameName
