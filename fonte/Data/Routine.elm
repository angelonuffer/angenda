module Data.Routine exposing (Routine, encodeRoutine, routineDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Routine =
    { id : String
    , title : String
    , recurrence : String -- "Diária", "Semanal", "Mensal"
    }


encodeRoutine : Routine -> Encode.Value
encodeRoutine routine =
    Encode.object
        [ ( "id", Encode.string routine.id )
        , ( "title", Encode.string routine.title )
        , ( "recurrence", Encode.string routine.recurrence )
        ]


routineDecoder : Decoder Routine
routineDecoder =
    Decode.map3 Routine
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "recurrence" Decode.string)
