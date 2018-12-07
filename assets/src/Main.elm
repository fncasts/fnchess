module Main exposing (main)

import Arithmetic exposing (isEven)
import Html exposing (Attribute, Html, button, div, h1, img, input, text)
import Html.Attributes exposing (src, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import List.Extra as List
import LocalStorage
import Model.Game as Game exposing (Game, GameName)
import Mouse
import Navigation
import Page.Game as Game
import Page.Home as Home
import Page.Login as Login
import Page.NotFound as NotFound
import Phoenix
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push
import Phoenix.Socket as Socket exposing (Socket)
import Piece
import Random.Pcg as Random
import Return
import Router exposing (Route(..))
import Task
import Util
import Uuid exposing (Uuid)


type Msg
    = RouteChanged Navigation.Location
    | SessionRestored (Result String (Maybe String))
    | LoginMsg Login.Msg
    | HomeMsg Home.Msg
    | GameMsg Game.Msg
    | NoOp


type Page
    = LoadingPage
    | LoginPage Login.Model
    | HomePage
    | GamePage Game.Model
    | NotFoundPage


type alias Model =
    { session : Session
    , route : Route
    , page : Page
    }


type Session
    = Restoring
    | LoggedOut
    | LoggedIn { username : String }


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Router.parse location
    in
    ( { route = route, session = Restoring, page = LoadingPage }
    , restoreSession
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( RouteChanged location, _ ) ->
            { model | route = Router.parse location } |> initPage

        ( SessionRestored result, _ ) ->
            case result of
                Ok (Just username) ->
                    { model | session = LoggedIn { username = username } }
                        |> initPage

                _ ->
                    { model | session = LoggedOut } |> initPage

        ( LoginMsg loginMsg, LoginPage loginPage ) ->
            let
                ( updatedLoginPage, outMsg ) =
                    Login.update loginMsg loginPage
            in
            case outMsg of
                Login.LoggedIn username ->
                    model
                        |> initSession username
                        |> Return.andThen initPage

                Login.NoMsg ->
                    ( { model | page = LoginPage updatedLoginPage }, Cmd.none )

        ( HomeMsg homeMsg, HomePage ) ->
            let
                homeCmd =
                    Home.update { socketUrl = socketUrl } homeMsg
            in
            ( model, Cmd.map HomeMsg homeCmd )

        ( GameMsg gameMsg, GamePage gamePage ) ->
            let
                ( updatedGameModel, gameCmd ) =
                    Game.update { socketUrl = socketUrl } gameMsg gamePage
            in
            ( { model | page = GamePage updatedGameModel }, Cmd.map GameMsg gameCmd )

        _ ->
            ( model, Cmd.none )


initPage : Model -> ( Model, Cmd Msg )
initPage model =
    let
        withSession callback =
            case model.session of
                Restoring ->
                    ( { model | page = LoadingPage }, Cmd.none )

                LoggedOut ->
                    ( { model | page = LoginPage Login.init }, Cmd.none )

                LoggedIn session ->
                    callback session
    in
    case model.route of
        HomeRoute ->
            withSession <|
                \session ->
                    ( { model | page = HomePage }, Cmd.none )

        GameRoute gameName ->
            withSession <|
                \session ->
                    ( { model | page = GamePage (Game.init gameName) }, Cmd.none )

        NotFoundRoute ->
            ( { model | page = NotFoundPage }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.page of
        LoadingPage ->
            text "loading"

        LoginPage loginPage ->
            Html.map LoginMsg <|
                Login.view loginPage

        HomePage ->
            Html.map HomeMsg <|
                Home.view

        NotFoundPage ->
            NotFound.view

        GamePage gamePage ->
            Html.map GameMsg <|
                Game.view gamePage


main : Program Never Model Msg
main =
    Navigation.program
        RouteChanged
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        LoadingPage ->
            Sub.none

        LoginPage loginPage ->
            Sub.none

        HomePage ->
            Sub.map HomeMsg <|
                Home.subscriptions socketUrl

        GamePage gamePage ->
            Sub.map GameMsg <|
                Game.subscriptions socketUrl gamePage

        NotFoundPage ->
            Sub.none


initSession : String -> Model -> ( Model, Cmd Msg )
initSession username model =
    let
        session =
            { username = username }
    in
    ( { model | session = LoggedIn session }, persistSession session )


restoreSession : Cmd Msg
restoreSession =
    LocalStorage.get "username"
        |> Task.mapError (\_ -> "unable to fetch username")
        |> Task.attempt SessionRestored


persistSession : { a | username : String } -> Cmd Msg
persistSession { username } =
    Task.attempt (\_ -> NoOp) (LocalStorage.set "username" username)


socketUrl : String
socketUrl =
    "ws://localhost:4000/socket/websocket"


socket : Socket Msg
socket =
    Socket.init socketUrl
