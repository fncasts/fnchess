module Page.Login exposing (Model, Msg(..), OutMsg(..), init, update, view)

import Html exposing (Attribute, Html, button, div, h1, img, input, text)
import Html.Attributes exposing (src, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Util exposing (onEnter)


type alias Model =
    { username : String
    }


type Msg
    = UsernameUpdated String
    | UsernameSubmitted


type OutMsg
    = LoggedIn String
    | NoMsg


init : Model
init =
    { username = "" }


update : Msg -> Model -> ( Model, OutMsg )
update msg model =
    case msg of
        UsernameUpdated username ->
            ( { model | username = username }, NoMsg )

        UsernameSubmitted ->
            ( model, LoggedIn model.username )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Login" ]
        , input [ onInput UsernameUpdated, value model.username, onEnter UsernameSubmitted ] []
        ]
