module Router exposing (Route(..), parse, toPath)

import Model.Game as Game exposing (GameName, gameNameFromString)
import Navigation
import UrlParser exposing ((</>), Parser, custom, map, oneOf, s)


type Route
    = HomeRoute
    | GameRoute GameName
    | NotFoundRoute


toPath : Route -> String
toPath route =
    case route of
        HomeRoute ->
            "/"

        GameRoute name ->
            "/game/" ++ Game.gameNameToString name

        NotFoundRoute ->
            "/notfound"


parse : Navigation.Location -> Route
parse location =
    UrlParser.parsePath matchers location
        |> Maybe.withDefault NotFoundRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map HomeRoute (s "")
        , map GameRoute (s "game" </> nameParser)
        ]


nameParser : Parser (GameName -> a) a
nameParser =
    custom "gameName" <|
        (Game.gameNameFromString >> Ok)
