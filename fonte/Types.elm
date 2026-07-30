module Types exposing (LoadedDataPayload, Model, Msg(..), loadedDataDecoder)

import Browser
import Browser.Navigation as Nav
import Data.Plan exposing (Plan, planDecoder)
import Data.Routine exposing (Routine, routineDecoder)
import Data.Task exposing (Task, taskDecoder)
import Json.Decode as Decode exposing (Decoder)
import Route exposing (Route)
import Url exposing (Url)


type alias Model =
    { key : Nav.Key
    , route : Route
    , tasks : List Task
    , routines : List Routine
    , plans : List Plan
    -- Form States
    , taskTitleInput : String
    , routineTitleInput : String
    , routineRecurrenceInput : String
    , planTitleInput : String
    , planDescInput : String
    , editingPlanId : Maybe String
    , newPlanTaskTitle : String
    }


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | DataLoadedRaw Decode.Value
    -- Form Inputs
    | InputTaskTitle String
    | InputRoutineTitle String
    | InputRoutineRecurrence String
    | InputPlanTitle String
    | InputPlanDesc String
    | InputPlanTaskTitle String
    -- Actions
    | CreateTask
    | SaveEditedTask String
    | ToggleTask String
    | DeleteTaskAction String
    | ArchiveTask String
    | RestoreTask String
    | CreateRoutine
    | DeleteRoutineAction String
    | GenerateTaskFromRoutine Routine
    | CreatePlan
    | DeletePlanAction String
    | StartEditPlan String
    | StopEditPlan
    | AddPlanTask String
    | TogglePlanTask String String
    | DeletePlanTask String String


type alias LoadedDataPayload =
    { tasks : List Task
    , routines : List Routine
    , plans : List Plan
    }


loadedDataDecoder : Decoder LoadedDataPayload
loadedDataDecoder =
    Decode.map3 LoadedDataPayload
        (Decode.field "tasks" (Decode.list taskDecoder))
        (Decode.field "routines" (Decode.list routineDecoder))
        (Decode.field "plans" (Decode.list planDecoder))
