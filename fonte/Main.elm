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
import Pages.Rotinas exposing (viewRotinas)
import Pages.Tarefas exposing (viewTarefas)
import Ports
import Route exposing (Route(..))
import Types exposing (Model, Msg(..))
import Url exposing (Url)


-- MAIN

type alias Flags =
    { today : String
    , seed : Int
    }


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , route = Route.fromUrl url
      , tasks = []
      , routines = []
      , plans = []
      , taskTitleInput = ""
      , taskDateInput = ""
      , routineTitleInput = ""
      , routineRecurrenceInput = "Diária"
      , planTitleInput = ""
      , planDescInput = ""
      , editingPlanId = Nothing
      , newPlanTaskTitle = ""
      , today = flags.today
      , drawerOpen = False
      , seed = flags.seed
      , counter = 1
      }
    , Ports.loadData ()
    )


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

                ( newPlanTitleInput, newPlanDescInput ) =
                    case newRoute of
                        AdicionarPlano ->
                            ( model.planTitleInput, model.planDescInput )

                        EditarPlano planId ->
                            let
                                maybePlan =
                                    model.plans
                                        |> List.filter (\p -> p.id == planId)
                                        |> List.head
                            in
                            ( maybePlan |> Maybe.map .title |> Maybe.withDefault ""
                            , maybePlan |> Maybe.map .description |> Maybe.withDefault ""
                            )

                        _ ->
                            ( "", "" )
            in
            ( { model
                | route = newRoute
                , taskTitleInput = newTitleInput
                , taskDateInput = newDateInput
                , planTitleInput = newPlanTitleInput
                , planDescInput = newPlanDescInput
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

                        ( newPlanTitleInput, newPlanDescInput ) =
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
                                    )

                                _ ->
                                    ( model.planTitleInput, model.planDescInput )

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
                    in
                    ( { model
                        | tasks = archivedTasks
                        , routines = payload.routines
                        , plans = payload.plans
                        , taskTitleInput = newTitleInput
                        , taskDateInput = newDateInput
                        , planTitleInput = newPlanTitleInput
                        , planDescInput = newPlanDescInput
                      }
                    , archiveCmds
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

        InputPlanTitle val ->
            ( { model | planTitleInput = val }, Cmd.none )

        InputPlanDesc val ->
            ( { model | planDescInput = val }, Cmd.none )

        InputPlanTaskTitle val ->
            ( { model | newPlanTaskTitle = val }, Cmd.none )

        CreateTask ->
            if String.trim model.taskTitleInput == "" then
                ( model, Cmd.none )

            else
                case model.route of
                    Route.AdicionarTarefa (Just planId) ->
                        let
                            ( taskId, nextSeed ) =
                                generateUuid model.counter model.seed

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
                                        { id = "task_" ++ taskId
                                        , title = model.taskTitleInput
                                        , completed = False
                                        , origin = "plano:" ++ planId ++ ":" ++ taskId
                                        , createdAt = "Plano: " ++ plan.title
                                        , history = []
                                        , archived = False
                                        , date = model.taskDateInput
                                        }
                                in
                                ( { model
                                    | plans = updatedPlans
                                    , tasks = model.tasks ++ [ newTask ]
                                    , taskTitleInput = ""
                                    , taskDateInput = ""
                                    , seed = nextSeed
                                    , counter = model.counter + 1
                                  }
                                , Cmd.batch
                                    [ Ports.savePlan (Plan.encodePlan plan)
                                    , Ports.saveTask (Task.encodeTask newTask)
                                    , Nav.pushUrl model.key ("/planos/editar/" ++ planId)
                                    ]
                                )

                            Nothing ->
                                ( model, Cmd.none )

                    _ ->
                        let
                            ( uuid, nextSeed ) =
                                generateUuid model.counter model.seed

                            newTask =
                                { id = uuid
                                , title = model.taskTitleInput
                                , completed = False
                                , origin = "avulsa"
                                , createdAt = "Agora"
                                , history = []
                                , archived = False
                                , date = model.taskDateInput
                                }
                        in
                        ( { model | tasks = model.tasks ++ [ newTask ], taskTitleInput = "", taskDateInput = "", seed = nextSeed, counter = model.counter + 1 }
                        , Cmd.batch
                            [ Ports.saveTask (Task.encodeTask newTask)
                            , Nav.pushUrl model.key "/tarefas"
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
                    ( uuid, nextSeed ) =
                        generateUuid model.counter model.seed

                    newRoutine =
                        { id = uuid
                        , title = model.routineTitleInput
                        , recurrence = model.routineRecurrenceInput
                        }
                in
                ( { model | routines = model.routines ++ [ newRoutine ], routineTitleInput = "", seed = nextSeed, counter = model.counter + 1 }
                , Ports.saveRoutine (Routine.encodeRoutine newRoutine)
                )

        DeleteRoutineAction id ->
            ( { model | routines = List.filter (\r -> r.id /= id) model.routines }
            , Ports.deleteRoutine id
            )

        GenerateTaskFromRoutine routine ->
            let
                ( uuid, nextSeed ) =
                    generateUuid model.counter model.seed

                newTask =
                    { id = uuid
                    , title = routine.title
                    , completed = False
                    , origin = "rotina:" ++ routine.title
                    , createdAt = "Rotina (" ++ routine.recurrence ++ ")"
                    , history = []
                    , archived = False
                    , date = ""
                    }
            in
            ( { model | tasks = model.tasks ++ [ newTask ], seed = nextSeed, counter = model.counter + 1 }
            , Ports.saveTask (Task.encodeTask newTask)
            )

        CreatePlan ->
            if String.trim model.planTitleInput == "" then
                ( model, Cmd.none )

            else
                let
                    ( uuid, nextSeed ) =
                        generateUuid model.counter model.seed

                    newPlan =
                        { id = uuid
                        , title = model.planTitleInput
                        , description = model.planDescInput
                        , tasks = []
                        , archived = False
                        }
                in
                ( { model
                    | plans = model.plans ++ [ newPlan ]
                    , planTitleInput = ""
                    , planDescInput = ""
                    , seed = nextSeed
                    , counter = model.counter + 1
                  }
                , Cmd.batch
                    [ Ports.savePlan (Plan.encodePlan newPlan)
                    , Nav.pushUrl model.key "/planos"
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
                                { plan | title = String.trim model.planTitleInput, description = model.planDescInput }

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
                    ( taskId, nextSeed ) =
                        generateUuid model.counter model.seed

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
                                { id = "task_" ++ taskId
                                , title = model.newPlanTaskTitle
                                , completed = False
                                , origin = "plano:" ++ planId ++ ":" ++ taskId
                                , createdAt = "Plano: " ++ plan.title
                                , history = []
                                , archived = False
                                , date = ""
                                }
                        in
                        ( { model
                            | plans = updatedPlans
                            , tasks = model.tasks ++ [ newTask ]
                            , newPlanTaskTitle = ""
                            , seed = nextSeed
                            , counter = model.counter + 1
                          }
                        , Cmd.batch
                            [ Ports.savePlan (Plan.encodePlan plan)
                            , Ports.saveTask (Task.encodeTask newTask)
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


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.dataLoaded DataLoadedRaw


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

                        Planos ->
                            viewPlanos model

                        AdicionarPlano ->
                            viewNovoPlano model

                        EditarPlano planId ->
                            viewEditarPlano model planId

                        Arquivo ->
                            viewArquivo model
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
        , viewDrawerLink "/rotinas" "repeat" "Rotinas" (currentRoute == Rotinas)
        , viewDrawerLink "/arquivo" "archive" "Arquivo" (currentRoute == Arquivo)
        ]


-- HEADER & NAVIGATION

viewHeader : Model -> Html Msg
viewHeader model =
    let
        currentRoute =
            model.route
    in
    header [ class "bg-red-700 text-white shadow-md relative z-30" ]
        [ div [ class "max-w-5xl w-full mx-auto px-4 py-3 flex items-center gap-4" ]
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
                    , viewDrawerLink "/rotinas" "repeat" "Rotinas" (currentRoute == Rotinas)
                    , viewDrawerLink "/arquivo" "archive" "Arquivo" (currentRoute == Arquivo)
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


-- UUID GENERATOR

toHex : Int -> String
toHex n =
    case n of
        0 -> "0"
        1 -> "1"
        2 -> "2"
        3 -> "3"
        4 -> "4"
        5 -> "5"
        6 -> "6"
        7 -> "7"
        8 -> "8"
        9 -> "9"
        10 -> "a"
        11 -> "b"
        12 -> "c"
        13 -> "d"
        14 -> "e"
        15 -> "f"
        _ -> "0"


toYHex : Int -> String
toYHex n =
    case n of
        0 -> "8"
        1 -> "9"
        2 -> "a"
        3 -> "b"
        _ -> "8"


nextRandom : Int -> ( Int, Int )
nextRandom seed =
    let
        a = 1103515245
        c = 12345
        m = 2147483647
        nextSeed = (a * seed + c) |> modBy m
    in
    ( nextSeed, nextSeed )


nextRandomVal : Int -> Int -> Int -> ( Int, Int )
nextRandomVal minVal maxVal seed =
    let
        ( r, nextSeed ) = nextRandom seed
        range = maxVal - minVal + 1
        val = minVal + (r |> modBy range)
    in
    ( val, nextSeed )


to8DigitHex : Int -> String
to8DigitHex n =
    let
        h1 = n |> modBy 16 |> toHex
        h2 = (n // 16) |> modBy 16 |> toHex
        h3 = (n // 256) |> modBy 16 |> toHex
        h4 = (n // 4096) |> modBy 16 |> toHex
        h5 = (n // 65536) |> modBy 16 |> toHex
        h6 = (n // 1048576) |> modBy 16 |> toHex
        h7 = (n // 16777216) |> modBy 16 |> toHex
        h8 = (n // 268435456) |> modBy 16 |> toHex
    in
    h8 ++ h7 ++ h6 ++ h5 ++ h4 ++ h3 ++ h2 ++ h1


generateUuid : Int -> Int -> ( String, Int )
generateUuid counter seed0 =
    let
        h1 = to8DigitHex counter
        ( h2, seed2 ) = nextRandomHexList 4 seed0
        ( h3, seed3 ) = nextRandomHexList 3 seed2
        ( yVal, seed4 ) = nextRandomVal 0 3 seed3
        yChar = toYHex yVal
        ( h4, seed5 ) = nextRandomHexList 3 seed4
        ( h5, seed6 ) = nextRandomHexList 12 seed5
    in
    ( h1 ++ "-" ++ h2 ++ "-4" ++ h3 ++ "-" ++ yChar ++ h4 ++ "-" ++ h5
    , seed6
    )


nextRandomHexList : Int -> Int -> ( String, Int )
nextRandomHexList count seed =
    nextRandomHexListHelper count "" seed


nextRandomHexListHelper : Int -> String -> Int -> ( String, Int )
nextRandomHexListHelper count acc seed =
    if count <= 0 then
        ( acc, seed )
    else
        let
            ( val, nextSeed ) = nextRandomVal 0 15 seed
            hexChar = toHex val
        in
        nextRandomHexListHelper (count - 1) (acc ++ hexChar) nextSeed
