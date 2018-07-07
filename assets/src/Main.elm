module Main exposing (..)

import Html exposing (Html, div, h1, img, button, input, Attribute)
import Html.Attributes exposing (src, value)
import Html.Events exposing (onClick, onInput, on, keyCode)
import List.Extra as List
import Svg exposing (svg, rect, Svg, g, text_, text)
import Svg.Attributes exposing (width, height, rx, ry, viewBox, x, y, fill, fontSize, style, transform, class)
import Svg.Events exposing (onMouseDown, onMouseUp, onMouseMove)
import Arithmetic exposing (isEven)
import Piece
import Mouse
import Json.Decode as JD
import Json.Decode.Pipeline as JDP
import Navigation
import Router exposing (Route(..))
import Uuid exposing (Uuid)
import Random.Pcg as Random
import Page.Game as GamePage
import Json.Decode as JD
import Phoenix
import Phoenix.Push as Push
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Socket as Socket exposing (Socket)
import Model.Game as Game exposing (Game, GameName)


---- MODEL ----


type Model
    = SignedOut SignedOutModel
    | SignedIn SignedInModel


type alias SignedOutModel =
    { username : String
    }


type Username
    = Username String


type alias SignedInModel =
    { page : Page, route : Router.Route, username : Username }


type Page
    = HomePage
    | GamePage GamePage.Model
    | NotFoundPage


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        route =
            Router.parse location
    in
        ( SignedOut initSignedOut
        , Cmd.none
        )


initSignedOut : SignedOutModel
initSignedOut =
    { username = ""
    }


initSignedIn : String -> SignedInModel
initSignedIn username =
    { username = Username username
    , page = HomePage
    , route = Router.HomeRoute
    }



---- UPDATE ----


type Msg
    = SignedInMsg SignedInMsg
    | UsernameUpdated String
    | SubmitUsername


type SignedInMsg
    = NoOp
    | RouteChanged Navigation.Location
    | StartGameClicked
    | GameMsg GamePage.Msg
    | NewGameResponseReceived (Result String GameName)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( UsernameUpdated username, SignedOut signedOutModel ) ->
            ( SignedOut { signedOutModel | username = username }, Cmd.none )

        ( SubmitUsername, SignedOut signedOutModel ) ->
            ( SignedIn <| initSignedIn signedOutModel.username, Cmd.none )

        ( SignedInMsg signedInMsg, SignedIn signedInModel ) ->
            let
                ( updatedSignedInModel, cmd ) =
                    updateSignedIn signedInMsg signedInModel
            in
                ( SignedIn updatedSignedInModel, Cmd.map SignedInMsg cmd )

        ( _, _ ) ->
            ( model, Cmd.none )


updateSignedIn : SignedInMsg -> SignedInModel -> ( SignedInModel, Cmd SignedInMsg )
updateSignedIn msg model =
    case ( Debug.log "Update" msg, model.page ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( RouteChanged location, _ ) ->
            let
                route =
                    Router.parse location
            in
                ( { model | route = route, page = pageFor route }, Cmd.none )

        ( StartGameClicked, HomePage ) ->
            ( model, requestNewGame NewGameResponseReceived )

        ( NewGameResponseReceived result, HomePage ) ->
            case result of
                Ok gameName ->
                    ( model, Navigation.newUrl <| Router.toPath <| Router.GameRoute gameName )

                Err message ->
                    todo "handle newGame failed" ( model, Cmd.none )

        ( GameMsg gameMsg, GamePage gameModel ) ->
            let
                ( updatedGameModel, gameCmd ) =
                    GamePage.update gameMsg gameModel
            in
                ( { model | page = GamePage updatedGameModel }
                , Cmd.map GameMsg gameCmd
                )

        _ ->
            ( model, Cmd.none )


pageFor : Route -> Page
pageFor route =
    case route of
        HomeRoute ->
            HomePage

        GameRoute uuid ->
            GamePage (GamePage.init uuid)

        NotFoundRoute ->
            NotFoundPage



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        SignedIn signedInModel ->
            signedInView signedInModel

        SignedOut signedOutModel ->
            signedOutView signedOutModel


signedOutView : SignedOutModel -> Html Msg
signedOutView signedOutModel =
    div []
        [ input [ onInput UsernameUpdated, value signedOutModel.username, onEnter SubmitUsername ] []
        ]


signedInView : SignedInModel -> Html Msg
signedInView signedInModel =
    Html.map SignedInMsg <|
        case signedInModel.page of
            HomePage ->
                button [ onClick StartGameClicked ] [ text "Start game" ]

            GamePage gameModel ->
                Html.map GameMsg (GamePage.view gameModel)

            NotFoundPage ->
                div [] [ text "where are you???" ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        SignedOut _ ->
            Sub.none

        SignedIn signedInModel ->
            Sub.map SignedInMsg <|
                Sub.batch <|
                    Debug.log "subscriptions" <|
                        [ pageSubscriptions signedInModel
                        , Phoenix.connect socket [ lobbyChannel ]
                        ]


lobbyChannel : Channel SignedInMsg
lobbyChannel =
    Channel.init "games:lobby"


pageSubscriptions : SignedInModel -> Sub SignedInMsg
pageSubscriptions signedInModel =
    case signedInModel.page of
        HomePage ->
            Sub.none

        GamePage gameModel ->
            Sub.map GameMsg (GamePage.subscriptions gameModel)

        NotFoundPage ->
            Sub.none



---- HELPERS ----


generateUuidCmd : (Uuid -> msg) -> Cmd msg
generateUuidCmd tagger =
    Random.generate tagger Uuid.uuidGenerator


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                JD.succeed msg
            else
                JD.fail "not ENTER"
    in
        on "keydown" (JD.andThen isEnter keyCode)


requestNewGame : (Result String GameName -> SignedInMsg) -> Cmd SignedInMsg
requestNewGame tagger =
    let
        push =
            Push.init "games:lobby" "create_game"
                |> Push.onOk (decodeGameCreated >> tagger)
    in
        Phoenix.push socketUrl push


decodeGameCreated : JD.Value -> Result String GameName
decodeGameCreated value =
    JD.decodeValue gameCreatedDecoder value


gameCreatedDecoder : JD.Decoder GameName
gameCreatedDecoder =
    JD.field "name" Game.nameDecoder


socket : Socket SignedInMsg
socket =
    Socket.init socketUrl


socketUrl : String
socketUrl =
    "ws://localhost:4000/socket/websocket"



---- PROGRAM ----


main : Program Never Model Msg
main =
    Navigation.program
        (SignedInMsg << RouteChanged)
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


todo : String -> a -> a
todo message a =
    let
        _ =
            Debug.log "todo" message
    in
        a
