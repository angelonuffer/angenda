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
        ]


planDecoder : Decoder Plan
planDecoder =
    Decode.map4 Plan
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "tasks" (Decode.list planTaskDecoder))
