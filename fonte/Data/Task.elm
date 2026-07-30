module Data.Task exposing (Task, encodeTask, taskDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Task =
    { id : String
    , title : String
    , completed : Bool
    , origin : String -- e.g. "avulsa", "rotina:id:title", "plano:id:taskId:title"
    , createdAt : String
    , history : List String
    , archived : Bool
    , date : String
    }


encodeTask : Task -> Encode.Value
encodeTask task =
    Encode.object
        [ ( "id", Encode.string task.id )
        , ( "title", Encode.string task.title )
        , ( "completed", Encode.bool task.completed )
        , ( "origin", Encode.string task.origin )
        , ( "createdAt", Encode.string task.createdAt )
        , ( "history", Encode.list Encode.string task.history )
        , ( "archived", Encode.bool task.archived )
        , ( "date", Encode.string task.date )
        ]


taskDecoder : Decoder Task
taskDecoder =
    Decode.succeed Task
        |> Decode.andThen (\f -> Decode.map f (Decode.field "id" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "title" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "completed" Decode.bool))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "origin" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "createdAt" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.oneOf [ Decode.field "history" (Decode.list Decode.string), Decode.succeed [] ]))
        |> Decode.andThen (\f -> Decode.map f (Decode.oneOf [ Decode.field "archived" Decode.bool, Decode.succeed False ]))
        |> Decode.andThen (\f -> Decode.map f (Decode.oneOf [ Decode.field "date" Decode.string, Decode.succeed "" ]))
