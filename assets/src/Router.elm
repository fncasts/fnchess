module Router exposing (parse, toPath, Route(..))

import Navigation
import Uuid exposing (Uuid)
import UrlParser exposing (oneOf, map, s, custom, Parser, (</>))


type Route
    = HomeRoute
    | GameRoute Uuid
    | NotFoundRoute


toPath : Route -> String
toPath route =
    case route of
        HomeRoute ->
            "/"

        GameRoute uuid ->
            "/game/" ++ Uuid.toString uuid

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
        , map GameRoute (s "game" </> uuidParser)
        ]


uuidParser : Parser (Uuid -> a) a
uuidParser =
    custom "UUID" <|
        (Uuid.fromString >> Result.fromMaybe "invalid game id")
