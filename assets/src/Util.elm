module Util exposing (todo, submatches, unindent, (=>))

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


(=>) a b =
    ( a, b )
