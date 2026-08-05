port module Ports exposing (loadData, saveTask, deleteTask, saveRoutine, deleteRoutine, savePlan, deletePlan, saveConfig, dataLoaded, requestUuids, receiveUuids)

import Json.Decode as Decode
import Json.Encode as Encode


-- PORTS

port loadData : () -> Cmd msg
port saveTask : Encode.Value -> Cmd msg
port deleteTask : String -> Cmd msg
port saveRoutine : Encode.Value -> Cmd msg
port deleteRoutine : String -> Cmd msg
port savePlan : Encode.Value -> Cmd msg
port deletePlan : String -> Cmd msg
port saveConfig : Encode.Value -> Cmd msg

port dataLoaded : (Decode.Value -> msg) -> Sub msg
port requestUuids : Int -> Cmd msg
port receiveUuids : (List String -> msg) -> Sub msg
