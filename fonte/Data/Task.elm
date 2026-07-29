module Data.Task exposing (Task, encodeTask, taskDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Task =
    { id : String
    , title : String
    , completed : Bool
    , origin : String -- e.g. "avulsa", "rotina:id:title", "plano:id:taskId:title"
    , createdAt : String
    }


encodeTask : Task -> Encode.Value
encodeTask task =
    Encode.object
        [ ( "id", Encode.string task.id )
        , ( "title", Encode.string task.title )
        , ( "completed", Encode.bool task.completed )
        , ( "origin", Encode.string task.origin )
        , ( "createdAt", Encode.string task.createdAt )
        ]


taskDecoder : Decoder Task
taskDecoder =
    Decode.map5 Task
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "completed" Decode.bool)
        (Decode.field "origin" Decode.string)
        (Decode.field "createdAt" Decode.string)
