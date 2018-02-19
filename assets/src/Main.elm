module Main exposing (..)

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
import Navigation
import Router exposing (Route(..))
import Uuid exposing (Uuid)
import Random.Pcg as Random
import Page.Game as GamePage


---- MODEL ----


type alias Model =
    { route : Router.Route
    , page : Page
    }


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
        ( { route = route
          , page = pageFor route
          }
        , Cmd.none
        )



---- UPDATE ----


type Msg
    = NoOp
    | RouteChanged Navigation.Location
    | StartGameClicked
    | GameUuidReady Uuid
    | GameMsg GamePage.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
            ( model, generateUuidCmd GameUuidReady )

        ( GameUuidReady uuid, HomePage ) ->
            ( model, Navigation.newUrl <| Router.toPath <| Router.GameRoute uuid )

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
    case model.page of
        HomePage ->
            button [ onClick StartGameClicked ] [ text "Start game" ]

        GamePage gameModel ->
            Html.map GameMsg (GamePage.view gameModel)

        NotFoundPage ->
            div [] [ text "where are you???" ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
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



---- PROGRAM ----


main : Program Never Model Msg
main =
    Navigation.program RouteChanged
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
