module Page.Home exposing (Msg(..), UpdateConfig, decodeGameCreated, gameCreatedDecoder, requestNewGame, subscriptions, update, view)

import Html exposing (Attribute, Html, button, div, h1, img, input, text)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD
import Model.Game as Game exposing (GameName)
import Navigation
import Phoenix
import Phoenix.Channel as Channel
import Phoenix.Push as Push
import Phoenix.Socket as Socket exposing (Socket)
import Router
import Util


type Msg
    = StartGameClicked
    | GameCreated (Result String GameName)


view : Html Msg
view =
    button [ onClick StartGameClicked ] [ text "Start game" ]


type alias UpdateConfig =
    { socketUrl : String
    }


update : UpdateConfig -> Msg -> Cmd Msg
update config msg =
    case msg of
        StartGameClicked ->
            requestNewGame config.socketUrl

        GameCreated result ->
            case result of
                Ok gameName ->
                    Navigation.newUrl <| Router.toPath <| Router.GameRoute gameName

                Err message ->
                    Util.todo "handle newGame failed"


requestNewGame : String -> Cmd Msg
requestNewGame socketUrl =
    let
        push =
            Push.init "games:lobby" "create_game"
                |> Push.onOk (decodeGameCreated >> GameCreated)
    in
    Phoenix.push socketUrl push


decodeGameCreated : JD.Value -> Result String GameName
decodeGameCreated value =
    JD.decodeValue gameCreatedDecoder value


gameCreatedDecoder : JD.Decoder GameName
gameCreatedDecoder =
    JD.field "name" Game.nameDecoder


subscriptions : String -> Sub Msg
subscriptions socketUrl =
    Phoenix.connect (Socket.init socketUrl) [ Channel.init "games:lobby" ]
