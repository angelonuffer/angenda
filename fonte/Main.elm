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
import Pages.Planos exposing (viewPlanos)
import Pages.Rotinas exposing (viewRotinas)
import Pages.Tarefas exposing (viewTarefas)
import Ports
import Route exposing (Route(..))
import Types exposing (Model, Msg(..))
import Url exposing (Url)


-- MAIN

main : Program String Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


init : String -> Url -> Nav.Key -> ( Model, Cmd Msg )
init today url key =
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
      , today = today
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
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

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
            in
            ( { model | route = newRoute, taskTitleInput = newTitleInput, taskDateInput = newDateInput }, Cmd.none )

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
                      }
                    , archiveCmds
                    )

                Err _ ->
                    ( model, Cmd.none )

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
                let
                    newId =
                        "task_" ++ String.fromInt (List.length model.tasks) ++ "_" ++ model.taskTitleInput
                        -- Simple unique key, indexdb or JS will keep it safe, but we can make a pseudo-random or simple timestamp id
                        |> String.replace " " "_"

                    newTask =
                        { id = newId
                        , title = model.taskTitleInput
                        , completed = False
                        , origin = "avulsa"
                        , createdAt = "Agora"
                        , history = []
                        , archived = False
                        , date = model.taskDateInput
                        }
                in
                ( { model | tasks = model.tasks ++ [ newTask ], taskTitleInput = "", taskDateInput = "" }
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
                        in
                        ( { model | tasks = updatedTasks, plans = updatedPlans, taskTitleInput = "", taskDateInput = "" }
                        , Cmd.batch
                            [ Ports.saveTask (Task.encodeTask updatedTask)
                            , planSyncCmd
                            , Nav.pushUrl model.key "/tarefas"
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
                    newId =
                        "routine_" ++ String.fromInt (List.length model.routines) ++ "_" ++ model.routineTitleInput
                        |> String.replace " " "_"

                    newRoutine =
                        { id = newId
                        , title = model.routineTitleInput
                        , recurrence = model.routineRecurrenceInput
                        }
                in
                ( { model | routines = model.routines ++ [ newRoutine ], routineTitleInput = "" }
                , Ports.saveRoutine (Routine.encodeRoutine newRoutine)
                )

        DeleteRoutineAction id ->
            ( { model | routines = List.filter (\r -> r.id /= id) model.routines }
            , Ports.deleteRoutine id
            )

        GenerateTaskFromRoutine routine ->
            let
                newTaskId =
                    "task_routine_" ++ routine.id ++ "_" ++ String.fromInt (List.length model.tasks)

                newTask =
                    { id = newTaskId
                    , title = routine.title
                    , completed = False
                    , origin = "rotina:" ++ routine.title
                    , createdAt = "Rotina (" ++ routine.recurrence ++ ")"
                    , history = []
                    , archived = False
                    , date = ""
                    }
            in
            ( { model | tasks = model.tasks ++ [ newTask ] }
            , Ports.saveTask (Task.encodeTask newTask)
            )

        CreatePlan ->
            if String.trim model.planTitleInput == "" then
                ( model, Cmd.none )

            else
                let
                    newId =
                        "plan_" ++ String.fromInt (List.length model.plans) ++ "_" ++ model.planTitleInput
                        |> String.replace " " "_"

                    newPlan =
                        { id = newId
                        , title = model.planTitleInput
                        , description = model.planDescInput
                        , tasks = []
                        }
                in
                ( { model
                    | plans = model.plans ++ [ newPlan ]
                    , planTitleInput = ""
                    , planDescInput = ""
                  }
                , Ports.savePlan (Plan.encodePlan newPlan)
                )

        DeletePlanAction id ->
            let
                -- Also remove plan tasks from main task list
                newTasks =
                    List.filter
                        (\t ->
                            not (String.startsWith ("plano:" ++ id ++ ":") t.origin)
                        )
                        model.tasks

                -- Delete port commands for all deleted tasks
                deletedTasksCmds =
                    model.tasks
                        |> List.filter (\t -> String.startsWith ("plano:" ++ id ++ ":") t.origin)
                        |> List.map (\t -> Ports.deleteTask t.id)
            in
            ( { model | plans = List.filter (\p -> p.id /= id) model.plans, tasks = newTasks }
            , Cmd.batch (Ports.deletePlan id :: deletedTasksCmds)
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
                    taskId =
                        "plantask_" ++ planId ++ "_" ++ String.fromInt (List.length model.tasks)

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

        DeletePlanTask planId planTaskId ->
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

                -- Also remove from main task list
                newTasks =
                    List.filter
                        (\t ->
                            t.origin /= ("plano:" ++ planId ++ ":" ++ planTaskId)
                        )
                        model.tasks

                -- Delete from db
                maybeTaskToDelete =
                    List.filter (\t -> t.origin == ("plano:" ++ planId ++ ":" ++ planTaskId)) model.tasks |> List.head

                deleteTaskCmd =
                    case maybeTaskToDelete of
                        Just task ->
                            Ports.deleteTask task.id

                        Nothing ->
                            Cmd.none
            in
            case maybePlan of
                Just plan ->
                    ( { model | plans = updatedPlans, tasks = newTasks }
                    , Cmd.batch [ Ports.savePlan (Plan.encodePlan plan), deleteTaskCmd ]
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
            [ viewHeader model.route
            , main_ [ class "flex-1 max-w-5xl w-full mx-auto p-4 md:p-6" ]
                [ case model.route of
                    Tarefas ->
                        viewTarefas model

                    AdicionarTarefa ->
                        viewNovaTarefa model

                    Route.EditarTarefa _ ->
                        viewNovaTarefa model

                    Rotinas ->
                        viewRotinas model

                    Planos ->
                        viewPlanos model

                    Arquivo ->
                        viewArquivo model
                ]
            , viewFooter
            ]
        ]
    }


-- HEADER & NAVIGATION

viewHeader : Route -> Html Msg
viewHeader currentRoute =
    header [ class "bg-red-700 text-white shadow-md" ]
        [ div [ class "max-w-5xl w-full mx-auto px-4 py-4 flex flex-col sm:flex-row items-center justify-between gap-4" ]
            [ a [ href "/tarefas", class "flex items-center gap-2 cursor-pointer text-white no-underline" ]
                [ img [ src "/brand-icon.png", class "w-8 h-8 object-contain" ] []
                , h1 [ class "text-2xl font-bold tracking-tight" ] [ text "Angenda" ]
                ]
            , nav [ class "flex items-center gap-1 bg-red-800/50 rounded-lg p-1" ]
                [ viewNavLink "/tarefas" "playlist_add_check" "Tarefas"
                    (case currentRoute of
                        Tarefas ->
                            True

                        AdicionarTarefa ->
                            True

                        Route.EditarTarefa _ ->
                            True

                        _ ->
                            False
                    )
                , viewNavLink "/rotinas" "repeat" "Rotinas" (currentRoute == Rotinas)
                , viewNavLink "/planos" "schema" "Planos" (currentRoute == Planos)
                , viewNavLink "/arquivo" "archive" "Arquivo" (currentRoute == Arquivo)
                ]
            ]
        ]

viewNavLink : String -> String -> String -> Bool -> Html Msg
viewNavLink url iconName label isActive =
    a
        [ href url
        , class <|
            "flex items-center gap-1.5 px-2.5 sm:px-4 py-2 rounded-md font-medium text-xs sm:text-sm transition-colors "
                ++ (if isActive then
                        "bg-white text-red-700 shadow-sm"

                    else
                        "text-red-100 hover:bg-red-600/40 hover:text-white"
                   )
        ]
        [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text iconName ]
        , text label
        ]


-- FOOTER

viewFooter : Html Msg
viewFooter =
    footer [ class "bg-slate-100 border-t border-slate-200 py-6 mt-12 text-center text-slate-500 text-sm" ]
        [ p [] [ text "Angenda © 2025 - Gerenciamento Inteligente de Tarefas" ]
        , p [ class "mt-1 text-xs" ] [ text "Desenvolvido em Elm, Tailwind CSS e IndexedDB" ]
        ]
