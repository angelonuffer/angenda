module Types exposing (Config, LoadedDataPayload, Model, Msg(..), encodeConfig, loadedDataDecoder)

import Browser
import Browser.Navigation as Nav
import Data.Plan exposing (Plan, planDecoder)
import Data.Routine exposing (Routine, routineDecoder)
import Data.Task exposing (Task, taskDecoder)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
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
    , taskDateInput : String
    , routineTitleInput : String
    , routineRecurrenceInput : String
    , routineSelectedDaysInput : List String
    , planTitleInput : String
    , planDescInput : String
    , planDeadlineInput : String
    , editingPlanId : Maybe String
    , newPlanTaskTitle : String
    , today : String
    , todayDayOfWeek : String
    , drawerOpen : Bool
    -- MQTT Sync State
    , mqttSyncEnabled : Bool
    , mqttBrokerUrl : String
    , mqttTopic : String
    , mqttEncryptionKey : String
    , mqttDeviceName : String
    , mqttStatus : String
    , mqttConnections : List { deviceName : String, lastSync : String }
    , uuidPool : List String
    }


type alias Config =
    { mqttSyncEnabled : Bool
    , mqttBrokerUrl : String
    , mqttTopic : String
    , mqttEncryptionKey : String
    , mqttDeviceName : String
    }


configDecoder : Decoder Config
configDecoder =
    Decode.map5 Config
        (Decode.field "mqttSyncEnabled" Decode.bool)
        (Decode.field "mqttBrokerUrl" Decode.string)
        (Decode.field "mqttTopic" Decode.string)
        (Decode.field "mqttEncryptionKey" Decode.string)
        (Decode.field "mqttDeviceName" Decode.string)


encodeConfig : Config -> Encode.Value
encodeConfig config =
    Encode.object
        [ ( "mqttSyncEnabled", Encode.bool config.mqttSyncEnabled )
        , ( "mqttBrokerUrl", Encode.string config.mqttBrokerUrl )
        , ( "mqttTopic", Encode.string config.mqttTopic )
        , ( "mqttEncryptionKey", Encode.string config.mqttEncryptionKey )
        , ( "mqttDeviceName", Encode.string config.mqttDeviceName )
        ]


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | DataLoadedRaw Decode.Value
    -- Drawer Actions
    | ToggleDrawer
    | CloseDrawer
    -- Form Inputs
    | InputTaskTitle String
    | InputTaskDate String
    | InputRoutineTitle String
    | InputRoutineRecurrence String
    | ToggleRoutineDay String
    | InputPlanTitle String
    | InputPlanDesc String
    | InputPlanDeadline String
    | InputPlanTaskTitle String
    -- MQTT Sync Inputs & Actions
    | InputMqttBrokerUrl String
    | InputMqttTopic String
    | InputMqttEncryptionKey String
    | InputMqttDeviceName String
    | ToggleMqttSync
    | TriggerMqttSync
    | GenerateMqttTopic
    | ReceiveUuids (List String)
    | MqttStatusUpdated String
    | MqttConnectionsUpdated Decode.Value
    -- Actions
    | CreateTask
    | SaveEditedTask String
    | ToggleTask String
    | DeleteTaskAction String
    | ArchiveTask String
    | RestoreTask String
    | CreateRoutine
    | SaveEditedRoutine String
    | ArchiveRoutine String
    | RestoreRoutine String
    | GenerateTaskFromRoutine Routine
    | CreatePlan
    | SaveEditedPlan String
    | ArchivePlan String
    | RestorePlan String
    | StartEditPlan String
    | StopEditPlan
    | AddPlanTask String
    | TogglePlanTask String String
    | ArchivePlanTask String String


type alias LoadedDataPayload =
    { tasks : List Task
    , routines : List Routine
    , plans : List Plan
    , config : Maybe Config
    }


loadedDataDecoder : Decoder LoadedDataPayload
loadedDataDecoder =
    Decode.map4 LoadedDataPayload
        (Decode.field "tasks" (Decode.list taskDecoder))
        (Decode.field "routines" (Decode.list routineDecoder))
        (Decode.field "plans" (Decode.list planDecoder))
        (Decode.maybe (Decode.field "config" configDecoder))
