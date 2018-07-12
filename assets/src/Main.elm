port module Main exposing (..)

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
import Task
import LocalStorage
import Util


---- MODEL ----


type Model
    = Restoring Router.Route
    | SignedOut SignedOutModel
    | SignedIn SignedInModel


type alias SignedOutModel =
    { username : String
    , route : Router.Route
    }


type Username
    = Username String


type alias SignedInModel =
    { page : Page, username : Username }


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
        ( Restoring route
        , restoreUsername
        )


initSignedOut : Router.Route -> SignedOutModel
initSignedOut route =
    { username = ""
    , route = route
    }


initSignedIn : String -> Route -> SignedInModel
initSignedIn username route =
    { username = Username username
    , page = pageFor route
    }



---- UPDATE ----


type Msg
    = SignedInMsg SignedInMsg
    | UsernameUpdated String
    | SubmitUsername
    | RouteChanged Navigation.Location
    | UsernameLoaded (Result String (Maybe String))
    | MsgNoOp


type SignedInMsg
    = SignedInMsgNoOp
    | StartGameClicked
    | GameMsg GamePage.Msg
    | NewGameResponseReceived (Result String GameName)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( UsernameLoaded result, Restoring route ) ->
            case result of
                Ok (Just username) ->
                    ( SignedIn <| initSignedIn username route, Cmd.none )

                _ ->
                    ( SignedOut <| initSignedOut route, Cmd.none )

        ( UsernameUpdated username, SignedOut signedOutModel ) ->
            ( SignedOut { signedOutModel | username = username }, Cmd.none )

        ( SubmitUsername, SignedOut signedOutModel ) ->
            ( SignedIn <| initSignedIn signedOutModel.username signedOutModel.route, persistUsername signedOutModel.username )

        ( SignedInMsg signedInMsg, SignedIn signedInModel ) ->
            let
                ( updatedSignedInModel, cmd ) =
                    updateSignedIn signedInMsg signedInModel
            in
                ( SignedIn updatedSignedInModel, Cmd.map SignedInMsg cmd )

        ( RouteChanged location, SignedOut signedOutModel ) ->
            ( SignedOut { signedOutModel | route = Router.parse location }, Cmd.none )

        ( RouteChanged location, SignedIn signedInModel ) ->
            ( SignedIn { signedInModel | page = pageFor <| Router.parse location }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


updateSignedIn : SignedInMsg -> SignedInModel -> ( SignedInModel, Cmd SignedInMsg )
updateSignedIn msg model =
    case ( msg, model.page ) of
        ( StartGameClicked, HomePage ) ->
            ( model, requestNewGame NewGameResponseReceived )

        ( NewGameResponseReceived result, HomePage ) ->
            case result of
                Ok gameName ->
                    ( model, Navigation.newUrl <| Router.toPath <| Router.GameRoute gameName )

                Err message ->
                    Util.todo "handle newGame failed"

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
        Restoring _ ->
            div [] [ text "loading..." ]

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
        Restoring _ ->
            Sub.none

        SignedOut _ ->
            Sub.none

        SignedIn signedInModel ->
            Sub.map SignedInMsg <|
                Sub.batch <|
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
        RouteChanged
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


persistUsername : String -> Cmd Msg
persistUsername username =
    Task.attempt (\_ -> MsgNoOp) (LocalStorage.set "username" username)


restoreUsername : Cmd Msg
restoreUsername =
    LocalStorage.get "username"
        |> Task.mapError (\_ -> "unable to fetch username")
        |> Task.attempt UsernameLoaded
