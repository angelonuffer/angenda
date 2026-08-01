module Data.Plan exposing (Plan, PlanTask, encodePlan, encodePlanTask, planDecoder, planTaskDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias PlanTask =
    { id : String
    , title : String
    , completed : Bool
    }


type alias Plan =
    { id : String
    , title : String
    , description : String
    , tasks : List PlanTask
    , archived : Bool
    }


encodePlanTask : PlanTask -> Encode.Value
encodePlanTask planTask =
    Encode.object
        [ ( "id", Encode.string planTask.id )
        , ( "title", Encode.string planTask.title )
        , ( "completed", Encode.bool planTask.completed )
        ]


planTaskDecoder : Decoder PlanTask
planTaskDecoder =
    Decode.map3 PlanTask
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "completed" Decode.bool)


encodePlan : Plan -> Encode.Value
encodePlan plan =
    Encode.object
        [ ( "id", Encode.string plan.id )
        , ( "title", Encode.string plan.title )
        , ( "description", Encode.string plan.description )
        , ( "tasks", Encode.list encodePlanTask plan.tasks )
        , ( "archived", Encode.bool plan.archived )
        ]


planDecoder : Decoder Plan
planDecoder =
    Decode.succeed Plan
        |> Decode.andThen (\f -> Decode.map f (Decode.field "id" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "title" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "description" Decode.string))
        |> Decode.andThen (\f -> Decode.map f (Decode.field "tasks" (Decode.list planTaskDecoder)))
        |> Decode.andThen (\f -> Decode.map f (Decode.oneOf [ Decode.field "archived" Decode.bool, Decode.succeed False ]))
