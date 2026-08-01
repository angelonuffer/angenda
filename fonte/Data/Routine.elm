module Data.Routine exposing (Routine, encodeRoutine, routineDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Routine =
    { id : String
    , title : String
    , recurrence : String -- "Diária", "Semanal", "Mensal"
    , lastGeneratedDate : String
    }


encodeRoutine : Routine -> Encode.Value
encodeRoutine routine =
    Encode.object
        [ ( "id", Encode.string routine.id )
        , ( "title", Encode.string routine.title )
        , ( "recurrence", Encode.string routine.recurrence )
        , ( "lastGeneratedDate", Encode.string routine.lastGeneratedDate )
        ]


routineDecoder : Decoder Routine
routineDecoder =
    Decode.succeed Routine
        |> Decode.andThen (\f -> Decode.map f (Decode.field "id" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "title" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "recurrence" Decode.string))
        |> Decode.andThen
            (\f ->
                Decode.maybe (Decode.field "lastGeneratedDate" Decode.string)
                    |> Decode.map (Maybe.withDefault "")
                    |> Decode.map f
            )
