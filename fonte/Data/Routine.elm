module Data.Routine exposing (Routine, encodeRoutine, routineDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Routine =
    { id : String
    , title : String
    , recurrence : String -- "Diária", "Semanal", "Mensal"
    , archived : Bool
    }


encodeRoutine : Routine -> Encode.Value
encodeRoutine routine =
    Encode.object
        [ ( "id", Encode.string routine.id )
        , ( "title", Encode.string routine.title )
        , ( "recurrence", Encode.string routine.recurrence )
        , ( "archived", Encode.bool routine.archived )
        ]


routineDecoder : Decoder Routine
routineDecoder =
    Decode.succeed Routine
        |> Decode.andThen (\f -> Decode.map f (Decode.field "id" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "title" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "recurrence" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.oneOf [ Decode.field "archived" Decode.bool, Decode.succeed False ]))
