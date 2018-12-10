module Util exposing ((=>), onEnter, submatches, todo, unindent)

import Html exposing (Attribute)
import Html.Events exposing (keyCode, on)
import Json.Decode as JD
import Regex


todo : String -> a
todo =
    Debug.crash


submatches : Regex.Regex -> String -> List (Maybe String)
submatches regex text =
    Regex.find Regex.All regex text
        |> List.head
        |> Maybe.map .submatches
        |> Maybe.withDefault []


unindent : String -> String
unindent text =
    text
        |> String.split "\n"
        |> List.map String.trim
        |> String.join "\n"
        |> String.trim


(=>) : a -> b -> ( a, b )
(=>) a b =
    ( a, b )


onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                JD.succeed msg

            else
                JD.fail "not ENTER"
    in
    on "keydown" (JD.andThen isEnter keyCode)
