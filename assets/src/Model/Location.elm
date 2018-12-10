module Model.Location exposing
    ( Location
    , a1
    , a2
    , a3
    , a4
    , a5
    , a6
    , a7
    , a8
    , all
    , b1
    , b2
    , b3
    , b4
    , b5
    , b6
    , b7
    , b8
    , c1
    , c2
    , c3
    , c4
    , c5
    , c6
    , c7
    , c8
    , d1
    , d2
    , d3
    , d4
    , d5
    , d6
    , d7
    , d8
    , decoder
    , e1
    , e2
    , e3
    , e4
    , e5
    , e6
    , e7
    , e8
    , encode
    , f1
    , f2
    , f3
    , f4
    , f5
    , f6
    , f7
    , f8
    , fileIndex
    , g1
    , g2
    , g3
    , g4
    , g5
    , g6
    , g7
    , g8
    , h1
    , h2
    , h3
    , h4
    , h5
    , h6
    , h7
    , h8
    , rankAndFileIndexes
    , rankIndex
    )

import Json.Decode as JD
import Json.Encode as JE
import List.Extra


type Location
    = Location Details


type alias Details =
    { rank : Int
    , file : Int
    , name : String
    }


encode : Location -> JE.Value
encode (Location { name }) =
    JE.string name


decoder : JD.Decoder Location
decoder =
    JD.string
        |> JD.andThen
            (\encoded ->
                case fromString encoded of
                    Ok location ->
                        JD.succeed location

                    Err message ->
                        JD.fail message
            )


fromString : String -> Result String Location
fromString encoded =
    all
        |> List.Extra.find (\(Location { name }) -> name == encoded)
        |> Result.fromMaybe ("invalid location: " ++ encoded)


rankIndex : Location -> Int
rankIndex (Location { rank }) =
    rank


fileIndex : Location -> Int
fileIndex (Location { file }) =
    file


rankAndFileIndexes : Location -> ( Int, Int )
rankAndFileIndexes (Location { rank, file }) =
    ( rank, file )


a1 =
    Location { rank = 0, file = 0, name = "a1" }


a2 =
    Location { rank = 0, file = 1, name = "a2" }


a3 =
    Location { rank = 0, file = 2, name = "a3" }


a4 =
    Location { rank = 0, file = 3, name = "a4" }


a5 =
    Location { rank = 0, file = 4, name = "a5" }


a6 =
    Location { rank = 0, file = 5, name = "a6" }


a7 =
    Location { rank = 0, file = 6, name = "a7" }


a8 =
    Location { rank = 0, file = 7, name = "a8" }


b1 =
    Location { rank = 1, file = 0, name = "b1" }


b2 =
    Location { rank = 1, file = 1, name = "b2" }


b3 =
    Location { rank = 1, file = 2, name = "b3" }


b4 =
    Location { rank = 1, file = 3, name = "b4" }


b5 =
    Location { rank = 1, file = 4, name = "b5" }


b6 =
    Location { rank = 1, file = 5, name = "b6" }


b7 =
    Location { rank = 1, file = 6, name = "b7" }


b8 =
    Location { rank = 1, file = 7, name = "b8" }


c1 =
    Location { rank = 2, file = 0, name = "c1" }


c2 =
    Location { rank = 2, file = 1, name = "c2" }


c3 =
    Location { rank = 2, file = 2, name = "c3" }


c4 =
    Location { rank = 2, file = 3, name = "c4" }


c5 =
    Location { rank = 2, file = 4, name = "c5" }


c6 =
    Location { rank = 2, file = 5, name = "c6" }


c7 =
    Location { rank = 2, file = 6, name = "c7" }


c8 =
    Location { rank = 2, file = 7, name = "c8" }


d1 =
    Location { rank = 3, file = 0, name = "d1" }


d2 =
    Location { rank = 3, file = 1, name = "d2" }


d3 =
    Location { rank = 3, file = 2, name = "d3" }


d4 =
    Location { rank = 3, file = 3, name = "d4" }


d5 =
    Location { rank = 3, file = 4, name = "d5" }


d6 =
    Location { rank = 3, file = 5, name = "d6" }


d7 =
    Location { rank = 3, file = 6, name = "d7" }


d8 =
    Location { rank = 3, file = 7, name = "d8" }


e1 =
    Location { rank = 4, file = 0, name = "e1" }


e2 =
    Location { rank = 4, file = 1, name = "e2" }


e3 =
    Location { rank = 4, file = 2, name = "e3" }


e4 =
    Location { rank = 4, file = 3, name = "e4" }


e5 =
    Location { rank = 4, file = 4, name = "e5" }


e6 =
    Location { rank = 4, file = 5, name = "e6" }


e7 =
    Location { rank = 4, file = 6, name = "e7" }


e8 =
    Location { rank = 4, file = 7, name = "e8" }


f1 =
    Location { rank = 5, file = 0, name = "f1" }


f2 =
    Location { rank = 5, file = 1, name = "f2" }


f3 =
    Location { rank = 5, file = 2, name = "f3" }


f4 =
    Location { rank = 5, file = 3, name = "f4" }


f5 =
    Location { rank = 5, file = 4, name = "f5" }


f6 =
    Location { rank = 5, file = 5, name = "f6" }


f7 =
    Location { rank = 5, file = 6, name = "f7" }


f8 =
    Location { rank = 5, file = 7, name = "f8" }


g1 =
    Location { rank = 6, file = 0, name = "g1" }


g2 =
    Location { rank = 6, file = 1, name = "g2" }


g3 =
    Location { rank = 6, file = 2, name = "g3" }


g4 =
    Location { rank = 6, file = 3, name = "g4" }


g5 =
    Location { rank = 6, file = 4, name = "g5" }


g6 =
    Location { rank = 6, file = 5, name = "g6" }


g7 =
    Location { rank = 6, file = 6, name = "g7" }


g8 =
    Location { rank = 6, file = 7, name = "g8" }


h1 =
    Location { rank = 7, file = 0, name = "h1" }


h2 =
    Location { rank = 7, file = 1, name = "h2" }


h3 =
    Location { rank = 7, file = 2, name = "h3" }


h4 =
    Location { rank = 7, file = 3, name = "h4" }


h5 =
    Location { rank = 7, file = 4, name = "h5" }


h6 =
    Location { rank = 7, file = 5, name = "h6" }


h7 =
    Location { rank = 7, file = 6, name = "h7" }


h8 =
    Location { rank = 7, file = 7, name = "h8" }


all =
    [ a1
    , a2
    , a3
    , a4
    , a5
    , a6
    , a7
    , a8
    , b1
    , b2
    , b3
    , b4
    , b5
    , b6
    , b7
    , b8
    , c1
    , c2
    , c3
    , c4
    , c5
    , c6
    , c7
    , c8
    , d1
    , d2
    , d3
    , d4
    , d5
    , d6
    , d7
    , d8
    , e1
    , e2
    , e3
    , e4
    , e5
    , e6
    , e7
    , e8
    , f1
    , f2
    , f3
    , f4
    , f5
    , f6
    , f7
    , f8
    , g1
    , g2
    , g3
    , g4
    , g5
    , g6
    , g7
    , g8
    , h1
    , h2
    , h3
    , h4
    , h5
    , h6
    , h7
    , h8
    ]
