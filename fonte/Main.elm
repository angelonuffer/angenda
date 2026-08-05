module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.Plan as Plan exposing (Plan, PlanTask)
import Data.Routine as Routine exposing (Routine)
import Data.Task as Task exposing (Task)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Pages.Arquivo exposing (viewArquivo)
import Pages.NovaTarefa exposing (viewNovaTarefa)
import Pages.Planos exposing (viewPlanos, viewNovoPlano, viewEditarPlano)
import Pages.Rotinas exposing (viewRotinas, viewNovaRotina)
import Pages.Sincronizar exposing (viewSincronizar)
import Pages.Tarefas exposing (viewTarefas)
import Ports
import Route exposing (Route(..))
import Types exposing (Model, Msg(..))
import Url exposing (Url)


-- MAIN

main : Program Decode.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : Decode.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flagsValue url key =
    let
        decoded =
            Decode.decodeValue
                (Decode.map2 (\t u -> { today = t, uuids = u })
                    (Decode.field "today" Decode.string)
                    (Decode.field "uuids" (Decode.list Decode.string))
                )
                flagsValue
                
        ( todayStr, initialUuids ) =
            case decoded of
                Ok vals ->
                    ( vals.today, vals.uuids )
                Err _ ->
                    ( "2026-01-01", [] )
    in
    ( { key = key
      , route = Route.fromUrl url
      , tasks = []
      , routines = []
      , plans = []
      , taskTitleInput = ""
      , taskDateInput = ""
      , routineTitleInput = ""
      , routineRecurrenceInput = "Diária"
      , routineSelectedDaysInput = []
      , planTitleInput = ""
      , planDescInput = ""
      , planDeadlineInput = ""
      , editingPlanId = Nothing
      , newPlanTaskTitle = ""
      , today = todayStr
      , drawerOpen = False
      , mqttSyncEnabled = False
      , mqttBrokerUrl = "wss://broker.hivemq.com:8884/mqtt"
      , mqttTopic = ""
      , mqttEncryptionKey = ""
      , mqttDeviceName = ""
      , mqttStatus = "Desconectado"
      , mqttConnections =
          [ { deviceName = "Meu Celular", lastSync = "Agora mesmo" }
          , { deviceName = "Notebook Casa", lastSync = "10 min atrás" }
          ]
      , uuidPool = initialUuids
      }
    , Ports.loadData ()
    )


-- HELPERS

getUuid : List String -> ( String, List String )
getUuid pool =
    case pool of
        h :: t -> ( h, t )
        [] -> ( "temp-uuid-" ++ String.fromInt (1), [] )

getUuids : Int -> List String -> ( List String, List String )
getUuids count pool =
    let
        taken = List.take count pool
        dropped = List.drop count pool
        needed = count - List.length taken
        fallbacks = List.map (\i -> "temp-uuid-" ++ String.fromInt i) (List.range 1 needed)
    in
    ( taken ++ fallbacks, dropped )


saveConfigCmd : Model -> Cmd Msg
saveConfigCmd model =
    Ports.saveConfig <|
        Types.encodeConfig
            { mqttSyncEnabled = model.mqttSyncEnabled
            , mqttBrokerUrl = model.mqttBrokerUrl
            , mqttTopic = model.mqttTopic
            , mqttEncryptionKey = model.mqttEncryptionKey
            , mqttDeviceName = model.mqttDeviceName
            }


-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( { model | drawerOpen = False }, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( { model | drawerOpen = False }, Nav.load href )

        UrlChanged url ->
            let
                newRoute =
                    Route.fromUrl url

                ( newTitleInput, newDateInput ) =
                    case newRoute of
                        Route.EditarTarefa id ->
                            let
                                maybeTask =
                                    model.tasks
                                        |> List.filter (\t -> t.id == id)
                                        |> List.head
                            in
                            ( maybeTask |> Maybe.map .title |> Maybe.withDefault ""
                            , maybeTask |> Maybe.map .date |> Maybe.withDefault ""
                            )

                        _ ->
                            ( "", "" )

                ( newRoutineTitleInput, newRoutineRecurrenceInput, newRoutineSelectedDaysInput ) =
                    case newRoute of
                        AdicionarRotina ->
                            ( model.routineTitleInput, model.routineRecurrenceInput, model.routineSelectedDaysInput )

                        Route.EditarRotina id ->
                            let
                                maybeRoutine =
                                    model.routines
                                        |> List.filter (\r -> r.id == id)
                                        |> List.head
                            in
                            ( maybeRoutine |> Maybe.map .title |> Maybe.withDefault ""
                            , maybeRoutine |> Maybe.map .recurrence |> Maybe.withDefault "Diária"
                            , maybeRoutine |> Maybe.map .selectedDays |> Maybe.withDefault []
                            )

                        _ ->
                            ( "", "Diária", [] )

                ( newPlanTitleInput, newPlanDescInput, newPlanDeadlineInput ) =
                    case newRoute of
                        AdicionarPlano ->
                            ( model.planTitleInput, model.planDescInput, model.planDeadlineInput )

                        EditarPlano planId ->
                            let
                                maybePlan =
                                    model.plans
                                        |> List.filter (\p -> p.id == planId)
                                        |> List.head
                            in
                            ( maybePlan |> Maybe.map .title |> Maybe.withDefault ""
                            , maybePlan |> Maybe.map .description |> Maybe.withDefault ""
                            , maybePlan |> Maybe.map .deadline |> Maybe.withDefault ""
                            )

                        _ ->
                            ( "", "", "" )
            in
            ( { model
                | route = newRoute
                , taskTitleInput = newTitleInput
                , taskDateInput = newDateInput
                , routineTitleInput = newRoutineTitleInput
                , routineRecurrenceInput = newRoutineRecurrenceInput
                , routineSelectedDaysInput = newRoutineSelectedDaysInput
                , planTitleInput = newPlanTitleInput
                , planDescInput = newPlanDescInput
                , planDeadlineInput = newPlanDeadlineInput
                , drawerOpen = False
              }
            , Cmd.none
            )

        DataLoadedRaw rawValue ->
            case Decode.decodeValue Types.loadedDataDecoder rawValue of
                Ok payload ->
                    let
                        ( newTitleInput, newDateInput ) =
                            case model.route of
                                Route.EditarTarefa id ->
                                    let
                                        maybeTask =
                                            payload.tasks
                                                |> List.filter (\t -> t.id == id)
                                                |> List.head
                                    in
                                    ( maybeTask |> Maybe.map .title |> Maybe.withDefault model.taskTitleInput
                                    , maybeTask |> Maybe.map .date |> Maybe.withDefault model.taskDateInput
                                    )

                                _ ->
                                    ( model.taskTitleInput, model.taskDateInput )

                        ( newRoutineTitleInput, newRoutineRecurrenceInput, newRoutineSelectedDaysInput ) =
                            case model.route of
                                AdicionarRotina ->
                                    ( model.routineTitleInput, model.routineRecurrenceInput, model.routineSelectedDaysInput )
                                Route.EditarRotina id ->
                                    let
                                        maybeRoutine =
                                            payload.routines
                                                |> List.filter (\r -> r.id == id)
                                                |> List.head
                                    in
                                    ( maybeRoutine |> Maybe.map .title |> Maybe.withDefault model.routineTitleInput
                                    , maybeRoutine |> Maybe.map .recurrence |> Maybe.withDefault model.routineRecurrenceInput
                                    , maybeRoutine |> Maybe.map .selectedDays |> Maybe.withDefault model.routineSelectedDaysInput
                                    )

                                _ ->
                                    ( model.routineTitleInput, model.routineRecurrenceInput, model.routineSelectedDaysInput )

                        ( newPlanTitleInput, newPlanDescInput, newPlanDeadlineInput ) =
                            case model.route of
                                Route.EditarPlano planId ->
                                    let
                                        maybePlan =
                                            payload.plans
                                                |> List.filter (\p -> p.id == planId)
                                                |> List.head
                                    in
                                    ( maybePlan |> Maybe.map .title |> Maybe.withDefault model.planTitleInput
                                    , maybePlan |> Maybe.map .description |> Maybe.withDefault model.planDescInput
                                    , maybePlan |> Maybe.map .deadline |> Maybe.withDefault model.planDeadlineInput
                                    )

                                _ ->
                                    ( model.planTitleInput, model.planDescInput, model.planDeadlineInput )

                        -- Automatic archiving of completed past tasks on load
                        tasksToArchive =
                            List.filter (\t -> t.completed && t.date /= "" && t.date < model.today && not t.archived) payload.tasks

                        archivedTasks =
                            List.map
                                (\t ->
                                    if t.completed && t.date /= "" && t.date < model.today && not t.archived then
                                        { t | archived = True }
                                    else
                                        t
                                )
                                payload.tasks

                        archiveCmds =
                            tasksToArchive
                                |> List.map (\t -> Ports.saveTask (Task.encodeTask { t | archived = True }))
                                |> Cmd.batch

                        -- Automatic task generation for daily routines
                        dailyRoutinesToUpdate =
                            List.filter (\r -> r.recurrence == "Diária" && not r.archived && r.lastGeneratedDate < model.today) payload.routines

                        updatedRoutinesList =
                            List.map
                                (\r ->
                                    if r.recurrence == "Diária" && not r.archived && r.lastGeneratedDate < model.today then
                                        { r | lastGeneratedDate = model.today }
                                    else
                                        r
                                )
                                payload.routines

                        routinesCount = List.length dailyRoutinesToUpdate
                        
                        (usedUuids, poolAfterRoutines) =
                            getUuids routinesCount model.uuidPool
                            
                        newGeneratedTasks =
                            List.map2
                                (\r uuid ->
                                    { id = uuid
                                    , title = r.title
                                    , completed = False
                                    , origin = "rotina:" ++ r.title
                                    , createdAt = "Rotina (" ++ r.recurrence ++ ")"
                                    , history = []
                                    , archived = False
                                    , date = model.today
                                    , updatedAt = 0
                                    }
                                )
                                dailyRoutinesToUpdate
                                usedUuids

                        generationCmds =
                            List.concat
                                [ List.map (\r -> Ports.saveRoutine (Routine.encodeRoutine { r | lastGeneratedDate = model.today })) dailyRoutinesToUpdate
                                , List.map (\t -> Ports.saveTask (Task.encodeTask t)) newGeneratedTasks
                                ]
                                |> Cmd.batch

                    in
                    ( { model
                        | tasks = archivedTasks ++ newGeneratedTasks
                        , routines = updatedRoutinesList
                        , plans = payload.plans
                        , taskTitleInput = newTitleInput
                        , taskDateInput = newDateInput
                        , routineTitleInput = newRoutineTitleInput
                        , routineRecurrenceInput = newRoutineRecurrenceInput
                        , routineSelectedDaysInput = newRoutineSelectedDaysInput
                        , planTitleInput = newPlanTitleInput
                      , uuidPool = poolAfterRoutines
                      , mqttSyncEnabled = payload.config |> Maybe.map .mqttSyncEnabled |> Maybe.withDefault model.mqttSyncEnabled
                      , mqttBrokerUrl = payload.config |> Maybe.map .mqttBrokerUrl |> Maybe.withDefault model.mqttBrokerUrl
                      , mqttTopic = payload.config |> Maybe.map .mqttTopic |> Maybe.withDefault model.mqttTopic
                      , mqttEncryptionKey = payload.config |> Maybe.map .mqttEncryptionKey |> Maybe.withDefault model.mqttEncryptionKey
                      , mqttDeviceName = payload.config |> Maybe.map .mqttDeviceName |> Maybe.withDefault model.mqttDeviceName
                      }
                    , let
                        replenishCmd = if List.length poolAfterRoutines < 10 then Ports.requestUuids 50 else Cmd.none
                      in
                      Cmd.batch [ archiveCmds, generationCmds, replenishCmd ]
                    )

                Err _ ->
                    ( model, Cmd.none )

        ToggleDrawer ->
            ( { model | drawerOpen = not model.drawerOpen }, Cmd.none )

        CloseDrawer ->
            ( { model | drawerOpen = False }, Cmd.none )

        InputTaskTitle val ->
            ( { model | taskTitleInput = val }, Cmd.none )

        InputTaskDate val ->
            ( { model | taskDateInput = val }, Cmd.none )

        InputRoutineTitle val ->
            ( { model | routineTitleInput = val }, Cmd.none )

        InputRoutineRecurrence val ->
            ( { model | routineRecurrenceInput = val }, Cmd.none )

        ToggleRoutineDay day ->
            let
                newSelectedDays =
                    if List.member day model.routineSelectedDaysInput then
                        List.filter (\d -> d /= day) model.routineSelectedDaysInput
                    else
                        model.routineSelectedDaysInput ++ [ day ]
            in
            ( { model | routineSelectedDaysInput = newSelectedDays }, Cmd.none )

        InputPlanTitle val ->
            ( { model | planTitleInput = val }, Cmd.none )

        InputPlanDesc val ->
            ( { model | planDescInput = val }, Cmd.none )

        InputPlanDeadline val ->
            ( { model | planDeadlineInput = val }, Cmd.none )

        InputPlanTaskTitle val ->
            ( { model | newPlanTaskTitle = val }, Cmd.none )

        InputMqttBrokerUrl val ->
            let newModel = { model | mqttBrokerUrl = val } in
            ( newModel, saveConfigCmd newModel )

        InputMqttTopic val ->
            let newModel = { model | mqttTopic = val } in
            ( newModel, saveConfigCmd newModel )

        InputMqttEncryptionKey val ->
            let newModel = { model | mqttEncryptionKey = val } in
            ( newModel, saveConfigCmd newModel )

        InputMqttDeviceName val ->
            let newModel = { model | mqttDeviceName = val } in
            ( newModel, saveConfigCmd newModel )

        ToggleMqttSync ->
            let
                newStatus =
                    if model.mqttSyncEnabled then
                        "Desconectado"
                    else
                        "Conectando..."
                newModel = { model | mqttSyncEnabled = not model.mqttSyncEnabled, mqttStatus = newStatus }
            in
            ( newModel, saveConfigCmd newModel )

        TriggerMqttSync ->
            let
                updatedConnections =
                    List.map (\c -> { c | lastSync = "Agora mesmo" }) model.mqttConnections
            in
            ( { model | mqttStatus = "Sincronizado", mqttConnections = updatedConnections }, Ports.loadData () )

        GenerateMqttTopic ->
            let
                ( uuid, newPool ) = getUuid model.uuidPool
                replenishCmd = if List.length newPool < 10 then Ports.requestUuids 50 else Cmd.none
                newModel = { model | mqttTopic = uuid, uuidPool = newPool }
            in
            ( newModel, Cmd.batch [ replenishCmd, saveConfigCmd newModel ] )

        ReceiveUuids uuids ->
            ( { model | uuidPool = model.uuidPool ++ uuids }, Cmd.none )

        CreateTask ->
            if String.trim model.taskTitleInput == "" then
                ( model, Cmd.none )

            else
                case model.route of
                    Route.AdicionarTarefa (Just planId) ->
                        let
                            ( uuid, poolAfterTask ) = getUuid model.uuidPool
                            taskId = "plantask_" ++ uuid

                            newPlanTask =
                                { id = taskId
                                , title = model.taskTitleInput
                                , completed = False
                                }

                            updatedPlans =
                                List.map
                                    (\p ->
                                        if p.id == planId then
                                            { p | tasks = p.tasks ++ [ newPlanTask ] }

                                        else
                                            p
                                    )
                                    model.plans

                            maybePlan =
                                List.filter (\p -> p.id == planId) updatedPlans |> List.head
                        in
                        case maybePlan of
                            Just plan ->
                                let
                                    newTask =
                                        { id = uuid
                                        , title = model.taskTitleInput
                                        , completed = False
                                        , origin = "plano:" ++ planId ++ ":" ++ taskId
                                        , createdAt = "Plano: " ++ plan.title
                                        , history = []
                                        , archived = False
                                        , date = model.taskDateInput
                                        , updatedAt = 0
                                        }
                                in
                                ( { model
                                    | plans = updatedPlans
                                    , tasks = model.tasks ++ [ newTask ]
                                    , taskTitleInput = ""
                                    , taskDateInput = ""
                                    , uuidPool = poolAfterTask
                                  }
                                , let
                                    replenishCmd = if List.length poolAfterTask < 10 then Ports.requestUuids 50 else Cmd.none
                                  in
                                  Cmd.batch
                                    [ Ports.savePlan (Plan.encodePlan plan)
                                    , Ports.saveTask (Task.encodeTask newTask)
                                    , Nav.pushUrl model.key ("/planos/editar/" ++ planId)
                                    , replenishCmd
                                    ]
                                )

                            Nothing ->
                                ( model, Cmd.none )

                    _ ->
                        let
                            ( newId, newPool ) = getUuid model.uuidPool

                            newTask =
                                { id = newId
                                , title = model.taskTitleInput
                                , completed = False
                                , origin = "avulsa"
                                , createdAt = "Agora"
                                {-- Simple unique key, indexdb or JS will keep it safe, but we can make a pseudo-random or simple timestamp id --}
                                , history = []
                                , archived = False
                                , date = model.taskDateInput
                                , updatedAt = 0
                                }
                        in
                        ( { model | tasks = model.tasks ++ [ newTask ], taskTitleInput = "", taskDateInput = "", uuidPool = newPool }
                        , let
                            replenishCmd = if List.length newPool < 10 then Ports.requestUuids 50 else Cmd.none
                          in
                          Cmd.batch
                            [ Ports.saveTask (Task.encodeTask newTask)
                            , Nav.pushUrl model.key "/tarefas"
                            , replenishCmd
                            ]
                        )

        SaveEditedTask id ->
            let
                trimmedTitle =
                    String.trim model.taskTitleInput
            in
            if trimmedTitle == "" then
                ( model, Cmd.none )

            else
                let
                    maybeTask =
                        List.filter (\t -> t.id == id) model.tasks |> List.head
                in
                case maybeTask of
                    Just task ->
                        let
                            baseUpdatedTask =
                                if trimmedTitle /= task.title then
                                    { task | title = trimmedTitle, history = task.history ++ [ task.title ], date = model.taskDateInput }
                                else
                                    { task | date = model.taskDateInput }

                            shouldArchive =
                                baseUpdatedTask.completed && baseUpdatedTask.date /= "" && baseUpdatedTask.date < model.today

                            updatedTask =
                                { baseUpdatedTask | archived = baseUpdatedTask.archived || shouldArchive }

                            updatedTasks =
                                List.map
                                    (\t ->
                                        if t.id == id then
                                            updatedTask

                                        else
                                            t
                                    )
                                    model.tasks

                            parts =
                                String.split ":" task.origin

                            ( updatedPlans, planSyncCmd ) =
                                case parts of
                                    [ "plano", planId, planTaskId ] ->
                                        let
                                            newPlans =
                                                List.map
                                                    (\p ->
                                                        if p.id == planId then
                                                            { p
                                                                | tasks =
                                                                    List.map
                                                                        (\pt ->
                                                                            if pt.id == planTaskId then
                                                                                { pt | title = trimmedTitle }

                                                                            else
                                                                                pt
                                                                        )
                                                                        p.tasks
                                                            }

                                                        else
                                                            p
                                                    )
                                                    model.plans

                                            maybePlan =
                                                List.filter (\p -> p.id == planId) newPlans |> List.head
                                        in
                                        case maybePlan of
                                            Just plan ->
                                                ( newPlans, Ports.savePlan (Plan.encodePlan plan) )

                                            Nothing ->
                                                ( model.plans, Cmd.none )

                                    _ ->
                                        ( model.plans, Cmd.none )
                            redirectUrl =
                                case String.split ":" task.origin of
                                    [ "plano", planId, _ ] ->
                                        "/planos/editar/" ++ planId

                                    _ ->
                                        "/tarefas"
                        in
                        ( { model | tasks = updatedTasks, plans = updatedPlans, taskTitleInput = "", taskDateInput = "" }
                        , Cmd.batch
                            [ Ports.saveTask (Task.encodeTask updatedTask)
                            , planSyncCmd
                            , Nav.pushUrl model.key redirectUrl
                            ]
                        )

                    Nothing ->
                        ( model, Cmd.none )

        ToggleTask id ->
            let
                updatedTasks =
                    List.map
                        (\t ->
                            if t.id == id then
                                let
                                    newCompleted =
                                        not t.completed

                                    shouldArchive =
                                        newCompleted && t.date /= "" && t.date < model.today
                                in
                                { t | completed = newCompleted, archived = t.archived || shouldArchive }

                            else
                                t
                        )
                        model.tasks

                maybeToggledTask =
                    List.filter (\t -> t.id == id) model.tasks |> List.head
            in
            case maybeToggledTask of
                Just task ->
                    let
                        newCompletedStatus =
                            not task.completed

                        shouldArchive =
                            newCompletedStatus && task.date /= "" && task.date < model.today

                        -- If the task originates from a plan, let's keep the plan synchronized!
                        -- Origin format for plan: "plano:planId:planTaskId"
                        parts =
                            String.split ":" task.origin

                        planSyncCmd =
                            case parts of
                                [ "plano", planId, planTaskId ] ->
                                    let
                                        updatedPlans =
                                            List.map
                                                (\p ->
                                                    if p.id == planId then
                                                        { p
                                                            | tasks =
                                                                List.map
                                                                    (\pt ->
                                                                        if pt.id == planTaskId then
                                                                            { pt | completed = newCompletedStatus }

                                                                        else
                                                                            pt
                                                                    )
                                                                    p.tasks
                                                        }

                                                    else
                                                        p
                                                )
                                                model.plans

                                        maybePlan =
                                            List.filter (\p -> p.id == planId) updatedPlans |> List.head
                                    in
                                    case maybePlan of
                                        Just plan ->
                                            Ports.savePlan (Plan.encodePlan plan)

                                        Nothing ->
                                            Cmd.none

                                _ ->
                                    Cmd.none

                        -- Also update the local plan state if synchronized
                        newPlans =
                            case parts of
                                [ "plano", planId, planTaskId ] ->
                                    List.map
                                        (\p ->
                                            if p.id == planId then
                                                { p
                                                    | tasks =
                                                        List.map
                                                            (\pt ->
                                                                if pt.id == planTaskId then
                                                                    { pt | completed = newCompletedStatus }

                                                                else
                                                                    pt
                                                            )
                                                            p.tasks
                                                }

                                            else
                                                p
                                        )
                                        model.plans

                                _ ->
                                    model.plans

                        updatedTask =
                            { task | completed = newCompletedStatus, archived = task.archived || shouldArchive }
                    in
                    ( { model | tasks = updatedTasks, plans = newPlans }
                    , Cmd.batch [ Ports.saveTask (Task.encodeTask updatedTask), planSyncCmd ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        DeleteTaskAction id ->
            let
                maybeTask =
                    List.filter (\t -> t.id == id) model.tasks |> List.head

                newTasks =
                    List.filter (\t -> t.id /= id) model.tasks

                -- If from a plan, delete from the plan too? Or just let it be. Let's delete the corresponding mirror connection in the plan as well to keep clean.
                planSyncCmd =
                    case maybeTask of
                        Just task ->
                            let
                                parts =
                                    String.split ":" task.origin
                            in
                            case parts of
                                [ "plano", planId, planTaskId ] ->
                                    let
                                        updatedPlans =
                                            List.map
                                                (\p ->
                                                    if p.id == planId then
                                                        { p | tasks = List.filter (\pt -> pt.id /= planTaskId) p.tasks }

                                                    else
                                                        p
                                                )
                                                model.plans

                                        maybePlan =
                                            List.filter (\p -> p.id == planId) updatedPlans |> List.head
                                    in
                                    case maybePlan of
                                        Just plan ->
                                            Ports.savePlan (Plan.encodePlan plan)

                                        Nothing ->
                                            Cmd.none

                                _ ->
                                    Cmd.none

                        Nothing ->
                            Cmd.none

                newPlans =
                    case maybeTask of
                        Just task ->
                            let
                                parts =
                                    String.split ":" task.origin
                            in
                            case parts of
                                [ "plano", planId, planTaskId ] ->
                                    List.map
                                        (\p ->
                                            if p.id == planId then
                                                { p | tasks = List.filter (\pt -> pt.id /= planTaskId) p.tasks }

                                            else
                                                p
                                        )
                                        model.plans

                                _ ->
                                    model.plans

                        Nothing ->
                            model.plans
            in
            ( { model | tasks = newTasks, plans = newPlans }
            , Cmd.batch [ Ports.deleteTask id, planSyncCmd ]
            )

        ArchiveTask id ->
            let
                updatedTasks =
                    List.map
                        (\t ->
                            if t.id == id then
                                { t | archived = True }

                            else
                                t
                        )
                        model.tasks

                maybeTask =
                    List.filter (\t -> t.id == id) model.tasks |> List.head
            in
            case maybeTask of
                Just task ->
                    let
                        updatedTask =
                            { task | archived = True }
                    in
                    ( { model | tasks = updatedTasks }
                    , Ports.saveTask (Task.encodeTask updatedTask)
                    )

                Nothing ->
                    ( model, Cmd.none )

        RestoreTask id ->
            let
                updatedTasks =
                    List.map
                        (\t ->
                            if t.id == id then
                                { t | archived = False }

                            else
                                t
                        )
                        model.tasks

                maybeTask =
                    List.filter (\t -> t.id == id) model.tasks |> List.head
            in
            case maybeTask of
                Just task ->
                    let
                        updatedTask =
                            { task | archived = False }
                    in
                    ( { model | tasks = updatedTasks }
                    , Ports.saveTask (Task.encodeTask updatedTask)
                    )

                Nothing ->
                    ( model, Cmd.none )

        CreateRoutine ->
            if String.trim model.routineTitleInput == "" then
                ( model, Cmd.none )

            else
                let
                    (uuids, poolAfterRoutine) = getUuids 2 model.uuidPool
                    (newId, taskId) = case uuids of
                        [u1, u2] -> (u1, u2)
                        _ -> ("temp-routine-uuid", "temp-task-uuid")

                    isDaily =
                        model.routineRecurrenceInput == "Diária"

                    newRoutine =
                        { id = newId
                        , title = model.routineTitleInput
                        , recurrence = model.routineRecurrenceInput
                        , archived = False
                        , lastGeneratedDate = if isDaily then model.today else ""
                        , selectedDays = model.routineSelectedDaysInput
                        , updatedAt = 0
                        }

                    maybeNewTask =
                        if isDaily then
                            Just
                                { id = taskId
                                , title = model.routineTitleInput
                                , completed = False
                                , origin = "rotina:" ++ model.routineTitleInput
                                , createdAt = "Rotina (" ++ model.routineRecurrenceInput ++ ")"
                                , history = []
                                , archived = False
                                , date = model.today
                                , updatedAt = 0
                                }
                        else
                            Nothing

                    replenishCmd = if List.length poolAfterRoutine < 10 then Ports.requestUuids 50 else Cmd.none
                    cmds =
                        case maybeNewTask of
                            Just newTask ->
                                [ Ports.saveRoutine (Routine.encodeRoutine newRoutine)
                                , Ports.saveTask (Task.encodeTask newTask)
                                , Nav.pushUrl model.key "/rotinas"
                                , replenishCmd
                                ]
                            Nothing ->
                                [ Ports.saveRoutine (Routine.encodeRoutine newRoutine)
                                , Nav.pushUrl model.key "/rotinas"
                                , replenishCmd
                                ]
                in
                ( { model | routines = model.routines ++ [ newRoutine ], tasks = model.tasks ++ (maybeNewTask |> Maybe.map List.singleton |> Maybe.withDefault []), routineTitleInput = "", routineRecurrenceInput = "Diária", routineSelectedDaysInput = [], uuidPool = poolAfterRoutine }
                , Cmd.batch cmds
                )

        SaveEditedRoutine id ->
            let
                trimmedTitle =
                    String.trim model.routineTitleInput
            in
            if trimmedTitle == "" then
                ( model, Cmd.none )

            else
                let
                    maybeRoutine =
                        List.filter (\r -> r.id == id) model.routines |> List.head
                in
                case maybeRoutine of
                    Just routine ->
                        let
                            isDaily =
                                model.routineRecurrenceInput == "Diária"

                            needsNewTask =
                                isDaily && routine.lastGeneratedDate < model.today

                            updatedRoutine =
                                { routine
                                | title = trimmedTitle
                                , recurrence = model.routineRecurrenceInput
                                , lastGeneratedDate = if needsNewTask then model.today else routine.lastGeneratedDate
                                , selectedDays = model.routineSelectedDaysInput
                                }

                            updatedRoutines =
                                List.map
                                    (\r ->
                                        if r.id == id then
                                            updatedRoutine
                                        else
                                            r
                                    )
                                    model.routines

                            (uuid, poolAfterSave) = if needsNewTask then getUuid model.uuidPool else ("", model.uuidPool)
                            maybeNewTask =
                                if needsNewTask then
                                    Just
                                        { id = uuid
                                        , title = trimmedTitle
                                        , completed = False
                                        , origin = "rotina:" ++ trimmedTitle
                                        , createdAt = "Rotina (" ++ model.routineRecurrenceInput ++ ")"
                                        , history = []
                                        , archived = False
                                        , date = model.today
                                        , updatedAt = 0
                                        }
                                else
                                    Nothing

                            replenishCmd = if List.length poolAfterSave < 10 then Ports.requestUuids 50 else Cmd.none
                            cmds =
                                case maybeNewTask of
                                    Just newTask ->
                                        [ Ports.saveRoutine (Routine.encodeRoutine updatedRoutine)
                                        , Ports.saveTask (Task.encodeTask newTask)
                                        , Nav.pushUrl model.key "/rotinas"
                                        , replenishCmd
                                        ]
                                    Nothing ->
                                        [ Ports.saveRoutine (Routine.encodeRoutine updatedRoutine)
                                        , Nav.pushUrl model.key "/rotinas"
                                        , replenishCmd
                                        ]
                        in
                        ( { model
                            | routines = updatedRoutines
                            , tasks = model.tasks ++ (maybeNewTask |> Maybe.map List.singleton |> Maybe.withDefault [])
                            , uuidPool = poolAfterSave
                          }
                        , Cmd.batch cmds
                        )

                    Nothing ->
                        ( model, Cmd.none )

        ArchiveRoutine id ->
            let
                updatedRoutines =
                    List.map
                        (\r ->
                            if r.id == id then
                                { r | archived = True }

                            else
                                r
                        )
                        model.routines

                maybeRoutine =
                    List.filter (\r -> r.id == id) model.routines |> List.head
            in
            case maybeRoutine of
                Just routine ->
                    let
                        updatedRoutine =
                            { routine | archived = True }
                    in
                    ( { model | routines = updatedRoutines }
                    , Ports.saveRoutine (Routine.encodeRoutine updatedRoutine)
                    )

                Nothing ->
                    ( model, Cmd.none )

        RestoreRoutine id ->
            let
                updatedRoutines =
                    List.map
                        (\r ->
                            if r.id == id then
                                { r | archived = False }

                            else
                                r
                        )
                        model.routines

                maybeRoutine =
                    List.filter (\r -> r.id == id) model.routines |> List.head
            in
            case maybeRoutine of
                Just routine ->
                    let
                        updatedRoutine =
                            { routine | archived = False }
                    in
                    ( { model | routines = updatedRoutines }
                    , Ports.saveRoutine (Routine.encodeRoutine updatedRoutine)
                    )

                Nothing ->
                    ( model, Cmd.none )

        GenerateTaskFromRoutine routine ->
            let
                (newTaskId, newPool) = getUuid model.uuidPool

                newTask =
                    { id = newTaskId
                    , title = routine.title
                    , completed = False
                    , origin = "rotina:" ++ routine.title
                    , createdAt = "Rotina (" ++ routine.recurrence ++ ")"
                    , history = []
                    , archived = False
                    , date = ""
                    , updatedAt = 0
                    }
                    
                replenishCmd = if List.length newPool < 10 then Ports.requestUuids 50 else Cmd.none
            in
            ( { model | tasks = model.tasks ++ [ newTask ], uuidPool = newPool }
            , Cmd.batch [ Ports.saveTask (Task.encodeTask newTask), replenishCmd ]
            )

        CreatePlan ->
            if String.trim model.planTitleInput == "" then
                ( model, Cmd.none )

            else
                let
                    (newId, newPool) = getUuid model.uuidPool

                    newPlan =
                        { id = newId
                        , title = model.planTitleInput
                        , description = model.planDescInput
                        , tasks = []
                        , archived = False
                        , deadline = model.planDeadlineInput
                        , updatedAt = 0
                        }
                    
                    replenishCmd = if List.length newPool < 10 then Ports.requestUuids 50 else Cmd.none
                in
                ( { model
                    | plans = model.plans ++ [ newPlan ]
                    , planTitleInput = ""
                    , planDescInput = ""
                    , planDeadlineInput = ""
                    , uuidPool = newPool
                  }
                , Cmd.batch
                    [ Ports.savePlan (Plan.encodePlan newPlan)
                    , Nav.pushUrl model.key "/planos"
                    , replenishCmd
                    ]
                )

        SaveEditedPlan id ->
            if String.trim model.planTitleInput == "" then
                ( model, Cmd.none )

            else
                let
                    maybePlan =
                        List.filter (\p -> p.id == id) model.plans |> List.head
                in
                case maybePlan of
                    Just plan ->
                        let
                            updatedPlan =
                                { plan | title = String.trim model.planTitleInput, description = model.planDescInput, deadline = model.planDeadlineInput }

                            updatedPlans =
                                List.map
                                    (\p ->
                                        if p.id == id then
                                            updatedPlan

                                        else
                                            p
                                    )
                                    model.plans
                        in
                        ( { model
                            | plans = updatedPlans
                            , planTitleInput = ""
                            , planDescInput = ""
                            , planDeadlineInput = ""
                          }
                        , Cmd.batch
                            [ Ports.savePlan (Plan.encodePlan updatedPlan)
                            , Nav.pushUrl model.key "/planos"
                            ]
                        )

                    Nothing ->
                        ( model, Cmd.none )

        ArchivePlan id ->
            let
                updatedPlans =
                    List.map
                        (\p ->
                            if p.id == id then
                                { p | archived = True }
                            else
                                p
                        )
                        model.plans

                maybePlan =
                    List.filter (\p -> p.id == id) model.plans |> List.head

                -- Also archive plan tasks from main task list
                updatedTasks =
                    List.map
                        (\t ->
                            if String.startsWith ("plano:" ++ id ++ ":") t.origin then
                                { t | archived = True }
                            else
                                t
                        )
                        model.tasks

                planTasksCmds =
                    model.tasks
                        |> List.filter (\t -> String.startsWith ("plano:" ++ id ++ ":") t.origin)
                        |> List.map (\t -> Ports.saveTask (Task.encodeTask { t | archived = True }))

                planCmd =
                    case maybePlan of
                        Just plan ->
                            [ Ports.savePlan (Plan.encodePlan { plan | archived = True }) ]
                        Nothing ->
                            []
            in
            ( { model | plans = updatedPlans, tasks = updatedTasks }
            , Cmd.batch (planCmd ++ planTasksCmds)
            )

        RestorePlan id ->
            let
                updatedPlans =
                    List.map
                        (\p ->
                            if p.id == id then
                                { p | archived = False }
                            else
                                p
                        )
                        model.plans

                maybePlan =
                    List.filter (\p -> p.id == id) model.plans |> List.head

                -- Also restore plan tasks in main task list
                updatedTasks =
                    List.map
                        (\t ->
                            if String.startsWith ("plano:" ++ id ++ ":") t.origin then
                                { t | archived = False }
                            else
                                t
                        )
                        model.tasks

                planTasksCmds =
                    model.tasks
                        |> List.filter (\t -> String.startsWith ("plano:" ++ id ++ ":") t.origin)
                        |> List.map (\t -> Ports.saveTask (Task.encodeTask { t | archived = False }))

                planCmd =
                    case maybePlan of
                        Just plan ->
                            [ Ports.savePlan (Plan.encodePlan { plan | archived = False }) ]
                        Nothing ->
                            []
            in
            ( { model | plans = updatedPlans, tasks = updatedTasks }
            , Cmd.batch (planCmd ++ planTasksCmds)
            )

        StartEditPlan id ->
            ( { model | editingPlanId = Just id, newPlanTaskTitle = "" }, Cmd.none )

        StopEditPlan ->
            ( { model | editingPlanId = Nothing, newPlanTaskTitle = "" }, Cmd.none )

        AddPlanTask planId ->
            if String.trim model.newPlanTaskTitle == "" then
                ( model, Cmd.none )

            else
                let
                    (uuid, newPool) = getUuid model.uuidPool
                    taskId = "plantask_" ++ uuid

                    newPlanTask =
                        { id = taskId
                        , title = model.newPlanTaskTitle
                        , completed = False
                        }

                    -- Update plan
                    updatedPlans =
                        List.map
                            (\p ->
                                if p.id == planId then
                                    { p | tasks = p.tasks ++ [ newPlanTask ] }

                                else
                                    p
                            )
                            model.plans

                    maybePlan =
                        List.filter (\p -> p.id == planId) updatedPlans |> List.head
                in
                case maybePlan of
                    Just plan ->
                        -- Mirror to main tasks list as well
                        let
                            newTask =
                                { id = uuid
                                , title = model.newPlanTaskTitle
                                , completed = False
                                , origin = "plano:" ++ planId ++ ":" ++ taskId
                                , createdAt = "Plano: " ++ plan.title
                                , history = []
                                , archived = False
                                , date = ""
                                , updatedAt = 0
                                }
                            
                            replenishCmd = if List.length newPool < 10 then Ports.requestUuids 50 else Cmd.none
                        in
                        ( { model
                            | plans = updatedPlans
                            , tasks = model.tasks ++ [ newTask ]
                            , newPlanTaskTitle = ""
                            , uuidPool = newPool
                          }
                        , Cmd.batch
                            [ Ports.savePlan (Plan.encodePlan plan)
                            , Ports.saveTask (Task.encodeTask newTask)
                            , replenishCmd
                            ]
                        )

                    Nothing ->
                        ( model, Cmd.none )

        TogglePlanTask planId planTaskId ->
            let
                updatedPlans =
                    List.map
                        (\p ->
                            if p.id == planId then
                                { p
                                    | tasks =
                                        List.map
                                            (\pt ->
                                                if pt.id == planTaskId then
                                                    { pt | completed = not pt.completed }

                                                else
                                                    pt
                                            )
                                            p.tasks
                                }

                            else
                                p
                        )
                        model.plans

                maybePlan =
                    List.filter (\p -> p.id == planId) updatedPlans |> List.head
            in
            case maybePlan of
                Just plan ->
                    let
                        maybePlanTask =
                            List.filter (\pt -> pt.id == planTaskId) plan.tasks |> List.head

                        completedStatus =
                            maybePlanTask |> Maybe.map .completed |> Maybe.withDefault False

                        -- Mirror update to main tasks list
                        updatedTasks =
                            List.map
                                (\t ->
                                    if t.origin == ("plano:" ++ planId ++ ":" ++ planTaskId) then
                                        let
                                            shouldArchive =
                                                completedStatus && t.date /= "" && t.date < model.today
                                        in
                                        { t | completed = completedStatus, archived = t.archived || shouldArchive }

                                    else
                                        t
                                )
                                model.tasks

                        maybeTask =
                            List.filter (\t -> t.origin == ("plano:" ++ planId ++ ":" ++ planTaskId)) model.tasks |> List.head

                        taskCmd =
                            case maybeTask of
                                Just task ->
                                    let
                                        shouldArchive =
                                            completedStatus && task.date /= "" && task.date < model.today
                                    in
                                    Ports.saveTask (Task.encodeTask { task | completed = completedStatus, archived = task.archived || shouldArchive })

                                Nothing ->
                                    Cmd.none
                    in
                    ( { model | plans = updatedPlans, tasks = updatedTasks }
                    , Cmd.batch [ Ports.savePlan (Plan.encodePlan plan), taskCmd ]
                    )

                Nothing ->
                    ( model, Cmd.none )

        ArchivePlanTask planId planTaskId ->
            let
                maybeTaskToArchive =
                    List.filter (\t -> t.origin == ("plano:" ++ planId ++ ":" ++ planTaskId)) model.tasks |> List.head
            in
            case maybeTaskToArchive of
                Just task ->
                    let
                        updatedTask =
                            { task | archived = True }

                        updatedTasks =
                            List.map
                                (\t ->
                                    if t.id == task.id then
                                        updatedTask
                                    else
                                        t
                                )
                                model.tasks
                    in
                    ( { model | tasks = updatedTasks }
                    , Ports.saveTask (Task.encodeTask updatedTask)
                    )

                Nothing ->
                    ( model, Cmd.none )

        MqttStatusUpdated status ->
            ( { model | mqttStatus = status }, Cmd.none )

        MqttConnectionsUpdated val ->
            let
                decoder =
                    Decode.list
                        (Decode.map2 (\device sync -> { deviceName = device, lastSync = sync })
                            (Decode.field "deviceName" Decode.string)
                            (Decode.field "lastSync" Decode.string)
                        )
            in
            case Decode.decodeValue decoder val of
                Ok list ->
                    ( { model | mqttConnections = list }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.dataLoaded DataLoadedRaw
        , Ports.receiveUuids ReceiveUuids
        , Ports.mqttStatusUpdate MqttStatusUpdated
        , Ports.mqttConnectionsUpdate MqttConnectionsUpdated
        ]


-- VIEW

view : Model -> Document Msg
view model =
    { title = "Angenda - Gerenciador de Tarefas"
    , body =
        [ div [ class "min-h-screen bg-slate-50 flex flex-col font-sans" ]
            [ viewHeader model
            , div [ class "flex-1 max-w-5xl w-full mx-auto flex flex-col md:flex-row" ]
                [ viewSidebar model
                , main_ [ class "flex-1 p-4 md:p-6 overflow-x-hidden" ]
                    [ case model.route of
                        Tarefas ->
                            viewTarefas model

                        AdicionarTarefa _ ->
                            viewNovaTarefa model

                        Route.EditarTarefa _ ->
                            viewNovaTarefa model

                        Rotinas ->
                            viewRotinas model

                        AdicionarRotina ->
                            viewNovaRotina model

                        Route.EditarRotina _ ->
                            viewNovaRotina model

                        Planos ->
                            viewPlanos model

                        AdicionarPlano ->
                            viewNovoPlano model

                        EditarPlano planId ->
                            viewEditarPlano model planId

                        Arquivo ->
                            viewArquivo model

                        Route.Sincronizar ->
                            viewSincronizar model
                    ]
                ]
            , viewFooter
            ]
        ]
    }


-- SIDEBAR FOR DESKTOP

viewSidebar : Model -> Html Msg
viewSidebar model =
    let
        currentRoute =
            model.route
    in
    aside [ class "hidden md:flex flex-col w-60 bg-white border-r border-slate-200 py-6 px-3 gap-1 flex-shrink-0" ]
        [ viewDrawerLink "/tarefas" "playlist_add_check" "Tarefas"
            (case currentRoute of
                Tarefas ->
                    True

                AdicionarTarefa _ ->
                    True

                Route.EditarTarefa _ ->
                    True

                _ ->
                    False
            )
        , viewDrawerLink "/planos" "schema" "Planos"
            (case currentRoute of
                Planos ->
                    True

                AdicionarPlano ->
                    True

                EditarPlano _ ->
                    True

                _ ->
                    False
            )
        , viewDrawerLink "/rotinas" "repeat" "Rotinas"
            (case currentRoute of
                Rotinas ->
                    True

                AdicionarRotina ->
                    True

                Route.EditarRotina _ ->
                    True

                _ ->
                    False
            )
        , viewDrawerLink "/arquivo" "archive" "Arquivo" (currentRoute == Arquivo)
        , viewDrawerLink "/sincronizar" "sync" "Sincronizar" (currentRoute == Route.Sincronizar)
        ]


-- HEADER & NAVIGATION

viewHeader : Model -> Html Msg
viewHeader model =
    let
        currentRoute =
            model.route
    in
    header [ class "bg-red-700 text-white shadow-md relative z-30" ]
        [ div [ class "max-w-5xl w-full mx-auto px-4 py-3 flex items-center justify-between" ]
            [ div [ class "flex items-center gap-4" ]
                [ button
                    [ onClick ToggleDrawer
                    , class "p-1.5 rounded-md hover:bg-red-600 focus:outline-none flex items-center justify-center text-white md:hidden"
                    , title "Menu"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "28px" ] [ text "menu" ] ]
                , a [ href "/tarefas", class "flex items-center gap-2 cursor-pointer text-white no-underline" ]
                    [ img [ src "/brand-icon.png", class "w-8 h-8 object-contain" ] []
                    , h1 [ class "text-2xl font-bold tracking-tight" ] [ text "Angenda" ]
                    ]
                ]
            , iframe
                [ src "https://kapivatar.net/perfil-autenticado"
                , style "width" "40px"
                , style "height" "40px"
                , style "border" "none"
                , style "border-radius" "50%"
                , class "bg-white overflow-hidden"
                ]
                []
            ]
        , -- Backdrop overlay when drawer is open
          if model.drawerOpen then
            div
                [ class "fixed inset-0 bg-slate-900/50 z-40 transition-opacity md:hidden"
                , onClick CloseDrawer
                ]
                []

          else
            text ""
        , -- Lateral drawer
          if model.drawerOpen then
            div
                [ class "fixed inset-y-0 left-0 w-72 bg-white z-50 shadow-2xl flex flex-col transition-all duration-300 ease-in-out md:hidden" ]
                [ -- Drawer Header
                  div [ class "bg-red-700 text-white p-4 flex items-center justify-between shadow-sm" ]
                    [ div [ class "flex items-center gap-2" ]
                        [ img [ src "/brand-icon.png", class "w-8 h-8 object-contain" ] []
                        , span [ class "text-xl font-bold tracking-tight" ] [ text "Angenda" ]
                        ]
                    , button
                        [ onClick CloseDrawer
                        , class "p-1.5 rounded-md hover:bg-red-600 focus:outline-none flex items-center justify-center text-white"
                        , title "Fechar"
                        ]
                        [ span [ class "material-symbols-outlined" ] [ text "close" ] ]
                    ]
                , -- Drawer Body with Links
                  nav [ class "flex-1 px-3 py-4 flex flex-col gap-1 overflow-y-auto" ]
                    [ viewDrawerLink "/tarefas" "playlist_add_check" "Tarefas"
                        (case currentRoute of
                            Tarefas ->
                                True

                            AdicionarTarefa _ ->
                                True

                            Route.EditarTarefa _ ->
                                True

                            _ ->
                                False
                        )
                    , viewDrawerLink "/planos" "schema" "Planos"
                        (case currentRoute of
                            Planos ->
                                True

                            AdicionarPlano ->
                                True

                            EditarPlano _ ->
                                True

                            _ ->
                                False
                        )
        , viewDrawerLink "/rotinas" "repeat" "Rotinas"
            (case currentRoute of
                Rotinas ->
                    True

                AdicionarRotina ->
                    True

                Route.EditarRotina _ ->
                    True

                _ ->
                    False
            )
                    , viewDrawerLink "/arquivo" "archive" "Arquivo" (currentRoute == Arquivo)
                    , viewDrawerLink "/sincronizar" "sync" "Sincronizar" (currentRoute == Route.Sincronizar)
                    ]
                ]

          else
            text ""
        ]

viewDrawerLink : String -> String -> String -> Bool -> Html Msg
viewDrawerLink url iconName label isActive =
    a
        [ href url
        , class <|
            "flex items-center gap-3 px-4 py-3 rounded-lg font-medium text-sm transition-all duration-150 "
                ++ (if isActive then
                        "bg-red-50 text-red-700 font-bold border-l-4 border-amber-500 pl-3"

                    else
                        "text-slate-600 hover:bg-slate-100 hover:text-slate-900 border-l-4 border-transparent pl-3"
                   )
        ]
        [ span [ class "material-symbols-outlined", style "font-size" "22px" ] [ text iconName ]
        , text label
        ]


-- FOOTER

viewFooter : Html Msg
viewFooter =
    footer [ class "bg-slate-100 border-t border-slate-200 py-6 mt-12 text-center text-slate-500 text-sm" ]
        [ p [] [ text "Angenda © 2025 - Gerenciamento Inteligente de Tarefas" ]
        , p [ class "mt-1 text-xs" ] [ text "Desenvolvido em Elm, Tailwind CSS e IndexedDB" ]
        ]
