port module Main exposing (main)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Svg exposing (svg, path)
import Svg.Attributes as SvgAttr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, top)


-- PORTS

port loadData : () -> Cmd msg
port saveTask : Encode.Value -> Cmd msg
port deleteTask : String -> Cmd msg
port saveRoutine : Encode.Value -> Cmd msg
port deleteRoutine : String -> Cmd msg
port savePlan : Encode.Value -> Cmd msg
port deletePlan : String -> Cmd msg

port dataLoaded : (Decode.Value -> msg) -> Sub msg


-- MAIN

main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


-- MODEL

type Route
    = Tarefas
    | Rotinas
    | Planos

type alias Task =
    { id : String
    , title : String
    , completed : Bool
    , origin : String -- e.g. "avulsa", "rotina:id:title", "plano:id:taskId:title"
    , createdAt : String
    }

type alias Routine =
    { id : String
    , title : String
    , recurrence : String -- "Diária", "Semanal", "Mensal"
    }

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


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , route = fromUrl url
      , tasks = []
      , routines = []
      , plans = []
      , taskTitleInput = ""
      , routineTitleInput = ""
      , routineRecurrenceInput = "Diária"
      , planTitleInput = ""
      , planDescInput = ""
      , editingPlanId = Nothing
      , newPlanTaskTitle = ""
      }
    , loadData ()
    )


-- ROUTING

routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Tarefas top
        , Parser.map Tarefas (Parser.s "tarefas")
        , Parser.map Rotinas (Parser.s "rotinas")
        , Parser.map Planos (Parser.s "planos")
        ]

fromUrl : Url -> Route
fromUrl url =
    Parser.parse routeParser url |> Maybe.withDefault Tarefas


-- JSON ENCODERS & DECODERS

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

encodeRoutine : Routine -> Encode.Value
encodeRoutine routine =
    Encode.object
        [ ( "id", Encode.string routine.id )
        , ( "title", Encode.string routine.title )
        , ( "recurrence", Encode.string routine.recurrence )
        ]

routineDecoder : Decoder Routine
routineDecoder =
    Decode.map3 Routine
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "recurrence" Decode.string)

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


-- UPDATE

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
    | ToggleTask String
    | DeleteTaskAction String
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
            ( { model | route = fromUrl url }, Cmd.none )

        DataLoadedRaw rawValue ->
            case Decode.decodeValue loadedDataDecoder rawValue of
                Ok payload ->
                    ( { model
                        | tasks = payload.tasks
                        , routines = payload.routines
                        , plans = payload.plans
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        InputTaskTitle val ->
            ( { model | taskTitleInput = val }, Cmd.none )

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
                        }
                in
                ( { model | tasks = model.tasks ++ [ newTask ], taskTitleInput = "" }
                , saveTask (encodeTask newTask)
                )

        ToggleTask id ->
            let
                updatedTasks =
                    List.map
                        (\t ->
                            if t.id == id then
                                { t | completed = not t.completed }

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
                                            savePlan (encodePlan plan)

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
                            { task | completed = newCompletedStatus }
                    in
                    ( { model | tasks = updatedTasks, plans = newPlans }
                    , Cmd.batch [ saveTask (encodeTask updatedTask), planSyncCmd ]
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
                                            savePlan (encodePlan plan)

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
            , Cmd.batch [ deleteTask id, planSyncCmd ]
            )

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
                , saveRoutine (encodeRoutine newRoutine)
                )

        DeleteRoutineAction id ->
            ( { model | routines = List.filter (\r -> r.id /= id) model.routines }
            , deleteRoutine id
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
                    }
            in
            ( { model | tasks = model.tasks ++ [ newTask ] }
            , saveTask (encodeTask newTask)
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
                , savePlan (encodePlan newPlan)
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
                        |> List.map (\t -> deleteTask t.id)
            in
            ( { model | plans = List.filter (\p -> p.id /= id) model.plans, tasks = newTasks }
            , Cmd.batch (deletePlan id :: deletedTasksCmds)
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
                                }
                        in
                        ( { model
                            | plans = updatedPlans
                            , tasks = model.tasks ++ [ newTask ]
                            , newPlanTaskTitle = ""
                          }
                        , Cmd.batch
                            [ savePlan (encodePlan plan)
                            , saveTask (encodeTask newTask)
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
                                        { t | completed = completedStatus }

                                    else
                                        t
                                )
                                model.tasks

                        maybeTask =
                            List.filter (\t -> t.origin == ("plano:" ++ planId ++ ":" ++ planTaskId)) model.tasks |> List.head

                        taskCmd =
                            case maybeTask of
                                Just task ->
                                    saveTask (encodeTask { task | completed = completedStatus })

                                Nothing ->
                                    Cmd.none
                    in
                    ( { model | plans = updatedPlans, tasks = updatedTasks }
                    , Cmd.batch [ savePlan (encodePlan plan), taskCmd ]
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
                            deleteTask task.id

                        Nothing ->
                            Cmd.none
            in
            case maybePlan of
                Just plan ->
                    ( { model | plans = updatedPlans, tasks = newTasks }
                    , Cmd.batch [ savePlan (encodePlan plan), deleteTaskCmd ]
                    )

                Nothing ->
                    ( model, Cmd.none )


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    dataLoaded DataLoadedRaw


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

                    Rotinas ->
                        viewRotinas model

                    Planos ->
                        viewPlanos model
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
                [ viewNavLink "/tarefas" "playlist_add_check" "Tarefas" (currentRoute == Tarefas)
                , viewNavLink "/rotinas" "repeat" "Rotinas" (currentRoute == Rotinas)
                , viewNavLink "/planos" "schema" "Planos" (currentRoute == Planos)
                ]
            ]
        ]

viewNavLink : String -> String -> String -> Bool -> Html Msg
viewNavLink url iconName label isActive =
    a
        [ href url
        , class <|
            "flex items-center gap-1.5 px-4 py-2 rounded-md font-medium text-sm transition-colors "
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


-- TAREFAS PAGE

viewTarefas : Model -> Html Msg
viewTarefas model =
    div [ class "space-y-6" ]
        [ -- Title & Description
          div [ class "flex flex-col md:flex-row md:items-center justify-between gap-4" ]
            [ div []
                [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Tarefas" ]
                , p [ class "text-slate-600 text-sm mt-1" ] [ text "Veja e gerencie todas as tarefas, incluindo as vindas de rotinas e planos." ]
                ]
            ]
        , -- Add Task Form
          Html.form [ onSubmit CreateTask, class "bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3" ]
            [ input
                [ type_ "text"
                , id "new-task-title"
                , placeholder "Adicionar nova tarefa avulsa..."
                , value model.taskTitleInput
                , onInput InputTaskTitle
                , class "flex-1 border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                ]
                []
            , button
                [ type_ "submit"
                , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm w-full sm:w-auto"
                ]
                [ text "Adicionar" ]
            ]
        , -- Tasks List
          div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden" ]
            [ if List.isEmpty model.tasks then
                div [ class "p-12 text-center space-y-3" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "task_alt" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma tarefa encontrada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Crie tarefas avulsas no formulário acima ou gere tarefas a partir de suas rotinas ou planos!" ]
                    ]

              else
                ul [ class "divide-y divide-slate-100" ]
                    (List.map viewTaskItem model.tasks)
            ]
        ]

viewTaskItem : Task -> Html Msg
viewTaskItem task =
    li [ class <| "p-4 flex items-center justify-between gap-4 hover:bg-slate-50 transition-colors " ++ if task.completed then "opacity-75" else "" ]
        [ div [ class "flex items-start gap-3 flex-1" ]
            [ button
                [ type_ "button"
                , onClick (ToggleTask task.id)
                , class <|
                    "mt-0.5 w-6 h-6 rounded-full border flex items-center justify-center transition-all "
                        ++ (if task.completed then
                                "bg-amber-500 border-amber-500 text-white"

                            else
                                "border-slate-300 text-transparent hover:border-red-500"
                           )
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "14px", style "font-weight" "bold" ] [ text "check" ] ]
            , div [ class "space-y-1" ]
                [ p
                    [ class <|
                        "font-medium "
                            ++ (if task.completed then
                                    "line-through text-slate-400"

                                else
                                    "text-slate-800"
                               )
                    ]
                    [ text task.title ]
                , div [ class "flex flex-wrap items-center gap-2" ]
                    [ -- Badge
                      viewOriginBadge task.origin
                    ]
                ]
            ]
        , button
            [ type_ "button"
            , onClick (DeleteTaskAction task.id)
            , class "text-slate-400 hover:text-rose-600 p-2 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
            , title "Excluir Tarefa"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "delete" ] ]
        ]

viewOriginBadge : String -> Html Msg
viewOriginBadge origin =
    if origin == "avulsa" then
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "push_pin" ]
            , text "Avulsa"
            ]

    else if String.startsWith "rotina:" origin then
        let
            routineTitle =
                String.dropLeft (String.length "rotina:") origin
        in
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-red-50 text-red-700 border border-red-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "repeat" ]
            , text <| "Rotina: " ++ routineTitle
            ]

    else if String.startsWith "plano:" origin then
        -- Format "plano:planId:planTaskId" -> we can just display "Plano"
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-amber-50 text-amber-800 border border-amber-100" ]
            [ span [ class "material-symbols-outlined", style "font-size" "12px" ] [ text "schema" ]
            , text "Plano"
            ]

    else
        span [ class "inline-flex items-center gap-1 rounded px-1.5 py-0.5 text-xs font-semibold bg-slate-100 text-slate-600" ]
            [ text origin ]


-- ROTINAS PAGE

viewRotinas : Model -> Html Msg
viewRotinas model =
    div [ class "space-y-6" ]
        [ div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Minhas Rotinas" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Defina tarefas recorrentes e crie instâncias delas na lista principal com um clique." ]
            ]
        , -- Add Routine Form
          Html.form [ onSubmit CreateRoutine, class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ h3 [ class "font-semibold text-slate-700 text-sm" ] [ text "Nova Rotina" ]
            , div [ class "grid grid-cols-1 md:grid-cols-3 gap-4" ]
                [ div [ class "md:col-span-2" ]
                    [ label [ for "new-routine-title", class "sr-only" ] [ text "Nome da Rotina" ]
                    , input
                        [ type_ "text"
                        , id "new-routine-title"
                        , placeholder "Ex: Beber 2L de água, Fazer academia..."
                        , value model.routineTitleInput
                        , onInput InputRoutineTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-routine-recurrence", class "sr-only" ] [ text "Recorrência" ]
                    , select
                        [ id "new-routine-recurrence"
                        , value model.routineRecurrenceInput
                        , onInput InputRoutineRecurrence
                        , class "w-full border border-slate-300 rounded-lg px-3 py-2 bg-white focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        [ option [ value "Diária" ] [ text "Diária" ]
                        , option [ value "Semanal" ] [ text "Semanal" ]
                        , option [ value "Mensal" ] [ text "Mensal" ]
                        ]
                    ]
                ]
            , div [ class "flex justify-end" ]
                [ button
                    [ type_ "submit"
                    , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm"
                    ]
                    [ text "Criar Rotina" ]
                ]
            ]
        , -- Routines List
          div [ class "grid grid-cols-1 md:grid-cols-2 gap-4" ]
            [ if List.isEmpty model.routines then
                div [ class "col-span-full bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "autorenew" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhuma rotina configurada" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Adicione rotinas para tarefas diárias, semanais ou mensais usando o formulário acima!" ]
                    ]

              else
                div [ class "col-span-full grid grid-cols-1 md:grid-cols-2 gap-4" ]
                    (List.map viewRoutineItem model.routines)
            ]
        ]

viewRoutineItem : Routine -> Html Msg
viewRoutineItem routine =
    div [ class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between gap-4 hover:shadow-md transition-shadow" ]
        [ div [ class "space-y-2" ]
            [ div [ class "flex items-start justify-between gap-4" ]
                [ h4 [ class "font-bold text-lg text-slate-800" ] [ text routine.title ]
                , button
                    [ type_ "button"
                    , onClick (DeleteRoutineAction routine.id)
                    , class "text-slate-400 hover:text-rose-600 p-1.5 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                    , title "Excluir Rotina"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "delete" ] ]
                ]
            , div [ class "flex items-center gap-1.5" ]
                [ span [ class "material-symbols-outlined text-red-500", style "font-size" "18px" ] [ text "repeat" ]
                , span [ class "text-xs font-semibold text-red-600 uppercase tracking-wider" ] [ text routine.recurrence ]
                ]
            ]
        , button
            [ type_ "button"
            , onClick (GenerateTaskFromRoutine routine)
            , class "w-full bg-slate-50 hover:bg-red-50 border border-slate-200 hover:border-red-200 text-red-600 hover:text-red-700 font-semibold py-2 rounded-lg transition-colors text-sm flex items-center justify-center gap-2"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "add" ]
            , text "Gerar Tarefa"
            ]
        ]


-- PLANOS PAGE

viewPlanos : Model -> Html Msg
viewPlanos model =
    div [ class "space-y-6" ]
        [ div []
            [ h2 [ class "text-2xl font-bold text-slate-800" ] [ text "Meus Planos" ]
            , p [ class "text-slate-600 text-sm mt-1" ] [ text "Crie sequências de tarefas estruturadas para alcançar um objetivo maior." ]
            ]
        , -- Add Plan Form
          Html.form [ onSubmit CreatePlan, class "bg-white p-5 rounded-xl border border-slate-200 shadow-sm space-y-4" ]
            [ h3 [ class "font-semibold text-slate-700 text-sm" ] [ text "Novo Plano (Projeto)" ]
            , div [ class "grid grid-cols-1 gap-4" ]
                [ div []
                    [ label [ for "new-plan-title", class "sr-only" ] [ text "Título do Plano" ]
                    , input
                        [ type_ "text"
                        , id "new-plan-title"
                        , placeholder "Ex: Aprender Alemão, Organizar Viagem de Férias..."
                        , value model.planTitleInput
                        , onInput InputPlanTitle
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                , div []
                    [ label [ for "new-plan-desc", class "sr-only" ] [ text "Descrição" ]
                    , textarea
                        [ id "new-plan-desc"
                        , placeholder "Descreva o objetivo do plano..."
                        , value model.planDescInput
                        , onInput InputPlanDesc
                        , class "w-full border border-slate-300 rounded-lg px-4 py-2 h-20 focus:outline-none focus:ring-2 focus:ring-red-500 text-slate-800"
                        ]
                        []
                    ]
                ]
            , div [ class "flex justify-end" ]
                [ button
                    [ type_ "submit"
                    , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-5 py-2 rounded-lg transition-colors shadow-sm"
                    ]
                    [ text "Criar Plano" ]
                ]
            ]
        , -- Plans List & Editor
          div [ class "space-y-4" ]
            [ if List.isEmpty model.plans then
                div [ class "bg-white p-12 text-center space-y-3 rounded-xl border border-slate-200 shadow-sm" ]
                    [ span [ class "material-symbols-outlined text-slate-300 text-5xl block mx-auto" ] [ text "schema" ]
                    , h3 [ class "text-lg font-medium text-slate-700" ] [ text "Nenhum plano cadastrado" ]
                    , p [ class "text-slate-500 text-sm max-w-md mx-auto" ] [ text "Comece criando um plano no formulário acima para estruturar sua jornada!" ]
                    ]

              else
                div [ class "space-y-4" ]
                    (List.map (viewPlanItem model) model.plans)
            ]
        ]

viewPlanItem : Model -> Plan -> Html Msg
viewPlanItem model plan =
    let
        isEditing =
            model.editingPlanId == Just plan.id

        totalTasks =
            List.length plan.tasks

        completedTasks =
            List.filter .completed plan.tasks |> List.length

        progressPercent =
            if totalTasks == 0 then
                0

            else
                round ((toFloat completedTasks / toFloat totalTasks) * 100)
    in
    div [ class "bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden hover:shadow-md transition-shadow" ]
        [ div [ class "p-5 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-50/50" ]
            [ div [ class "space-y-1 flex-1" ]
                [ h4 [ class "font-bold text-lg text-slate-800" ] [ text plan.title ]
                , p [ class "text-slate-500 text-sm" ] [ text plan.description ]
                , if totalTasks > 0 then
                    div [ class "flex items-center gap-3 mt-2" ]
                        [ div [ class "w-24 bg-slate-200 rounded-full h-2 overflow-hidden" ]
                            [ div [ class "bg-amber-500 h-full rounded-full transition-all duration-300", style "width" (String.fromInt progressPercent ++ "%") ] [] ]
                        , span [ class "text-xs font-semibold text-slate-600" ] [ text (String.fromInt completedTasks ++ "/" ++ String.fromInt totalTasks ++ " concluídas (" ++ String.fromInt progressPercent ++ "%)") ]
                        ]

                  else
                    p [ class "text-xs text-slate-400 italic mt-1" ] [ text "Nenhuma tarefa adicionada a este plano." ]
                ]
            , div [ class "flex items-center gap-2 self-start sm:self-center" ]
                [ button
                    [ type_ "button"
                    , id <| "gerenciar-plano-" ++ plan.id
                    , onClick (if isEditing then StopEditPlan else StartEditPlan plan.id)
                    , class <|
                        "font-semibold text-sm px-4 py-2 rounded-lg border transition-colors "
                            ++ (if isEditing then
                                    "bg-red-50 border-red-200 text-red-700 hover:bg-red-100"

                                else
                                    "bg-white border-slate-200 text-slate-600 hover:bg-slate-50"
                               )
                    ]
                    [ text (if isEditing then "Fechar" else "Gerenciar Tarefas") ]
                , button
                    [ type_ "button"
                    , onClick (DeletePlanAction plan.id)
                    , class "text-slate-400 hover:text-rose-600 p-2 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
                    , title "Excluir Plano"
                    ]
                    [ span [ class "material-symbols-outlined", style "font-size" "20px" ] [ text "delete" ] ]
                ]
            ]
        , if isEditing then
            div [ class "p-5 bg-white space-y-4 border-t border-slate-100" ]
                [ h5 [ class "font-semibold text-slate-700 text-sm" ] [ text "Sequência de Tarefas do Plano" ]
                , -- Form to add sequential tasks
                  Html.form
                    [ onSubmit (AddPlanTask plan.id)
                    , class "flex gap-2"
                    ]
                    [ input
                        [ type_ "text"
                        , id "new-plan-task"
                        , placeholder "Insira o próximo passo do plano..."
                        , value model.newPlanTaskTitle
                        , onInput InputPlanTaskTitle
                        , class "flex-1 border border-slate-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-red-500 text-sm text-slate-800"
                        ]
                        []
                    , button
                        [ type_ "submit"
                        , id "add-plan-task-btn"
                        , class "bg-red-600 hover:bg-red-700 text-white font-semibold px-4 py-1.5 rounded-lg text-sm transition-colors"
                        ]
                        [ text "Adicionar" ]
                    ]
                , -- List of current plan tasks
                  if List.isEmpty plan.tasks then
                    p [ class "text-sm text-slate-400 italic text-center py-4" ] [ text "Sem tarefas adicionadas a este plano. Adicione tarefas para iniciar a sequência!" ]

                  else
                    ol [ class "divide-y divide-slate-100 border border-slate-100 rounded-lg overflow-hidden bg-slate-50/20" ]
                        (List.indexedMap (viewPlanTaskItem plan.id) plan.tasks)
                ]

          else
            text ""
        ]

viewPlanTaskItem : String -> Int -> PlanTask -> Html Msg
viewPlanTaskItem planId index pt =
    li [ class <| "p-3 flex items-center justify-between gap-3 text-sm " ++ if pt.completed then "opacity-70 bg-amber-50/10" else "" ]
        [ div [ class "flex items-center gap-2" ]
            [ button
                [ type_ "button"
                , onClick (TogglePlanTask planId pt.id)
                , class <|
                    "w-5 h-5 rounded-full border flex items-center justify-center transition-all "
                        ++ (if pt.completed then
                                "bg-amber-500 border-amber-500 text-white"

                            else
                                "border-slate-300 text-transparent hover:border-red-500"
                           )
                ]
                [ span [ class "material-symbols-outlined", style "font-size" "12px", style "font-weight" "bold" ] [ text "check" ] ]
            , span [ class "font-semibold text-slate-400" ] [ text (String.fromInt (index + 1) ++ ".") ]
            , span [ class <| "font-medium " ++ if pt.completed then "line-through text-slate-400" else "text-slate-700" ] [ text pt.title ]
            ]
        , button
            [ type_ "button"
            , onClick (DeletePlanTask planId pt.id)
            , class "text-slate-400 hover:text-rose-600 p-1 rounded-lg hover:bg-rose-50 transition-all flex items-center justify-center"
            , title "Excluir Passo"
            ]
            [ span [ class "material-symbols-outlined", style "font-size" "18px" ] [ text "delete" ] ]
        ]
