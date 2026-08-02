module Route exposing (Route(..), fromUrl, routeParser)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, top)


type Route
    = Tarefas
    | Rotinas
    | AdicionarRotina
    | Planos
    | AdicionarTarefa (Maybe String)
    | EditarTarefa String
    | Arquivo
    | AdicionarPlano
    | EditarPlano String


routeParser : Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map Tarefas top
        , Parser.map Tarefas (Parser.s "tarefas")
        , Parser.map (AdicionarTarefa Nothing) (Parser.s "tarefas" </> Parser.s "nova")
        , Parser.map (\planId -> AdicionarTarefa (Just planId)) (Parser.s "tarefas" </> Parser.s "nova" </> Parser.string)
        , Parser.map EditarTarefa (Parser.s "tarefas" </> Parser.s "editar" </> Parser.string)
        , Parser.map Rotinas (Parser.s "rotinas")
        , Parser.map AdicionarRotina (Parser.s "rotinas" </> Parser.s "nova")
        , Parser.map Planos (Parser.s "planos")
        , Parser.map AdicionarPlano (Parser.s "planos" </> Parser.s "novo")
        , Parser.map EditarPlano (Parser.s "planos" </> Parser.s "editar" </> Parser.string)
        , Parser.map Arquivo (Parser.s "arquivo")
        ]


fromUrl : Url -> Route
fromUrl url =
    let
        decodedPath =
            Url.percentDecode url.path |> Maybe.withDefault url.path

        decodedUrl =
            { url | path = decodedPath }
    in
    Parser.parse routeParser decodedUrl |> Maybe.withDefault Tarefas
