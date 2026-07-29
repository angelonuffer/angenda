module Route exposing (Route(..), fromUrl, routeParser)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, top)


type Route
    = Tarefas
    | Rotinas
    | Planos


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
