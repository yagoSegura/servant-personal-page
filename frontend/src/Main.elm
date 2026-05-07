module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Url
import Types exposing (Proyecto, proyectosDecoder)

-- 1. MODELO
type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , proyectosStatus : Status
    }

type Status
    = Loading
    | Success (List Proyecto)
    | Failure Http.Error

type Route
    = Home
    | Portfolio
    | Blog
    | Contact
    | NotFound

-- 2. INIT
init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model key url (urlToRoute url) Loading
    , getProyectos
    )

-- 3. MENSAJES (UNIFICADO)
type Msg
    = ChangedUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotProyectos (Result Http.Error (List Proyecto))

-- 4. UPDATE (UNIFICADO)
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )
                Browser.External href ->
                    ( model, Nav.load href )

        ChangedUrl url ->
            ( { model | url = url, route = urlToRoute url }, Cmd.none )

        GotProyectos result ->
            case result of
                Ok lista ->
                    ( { model | proyectosStatus = Success lista }, Cmd.none )
                Err error ->
                    ( { model | proyectosStatus = Failure error }, Cmd.none )

-- 5. PETICIÓN HTTP
getProyectos : Cmd Msg
getProyectos =
    Http.get
        { url = "http://localhost:8080/portfolio"
        , expect = Http.expectJson GotProyectos proyectosDecoder
        }

-- 6. VISTA
view : Model -> Browser.Document Msg
view model =
    { title = "Mi Página Personal"
    , body =
        [ nav []
            [ ul []
                [ li [] [ a [ href "/" ] [ text "Home" ] ]
                , li [] [ a [ href "/portfolio" ] [ text "Portfolio" ] ]
                , li [] [ a [ href "/blog" ] [ text "Blog" ] ]
                , li [] [ a [ href "/contact" ] [ text "Contact" ] ]
                ]
            ]
        , mainContent model
        ]
    }

mainContent : Model -> Html Msg
mainContent model =
    case model.route of
        Home -> h1 [] [ text "Bienvenido" ]
        Portfolio ->
            div []
                [ h1 [] [ text "Mis Proyectos" ]
                , case model.proyectosStatus of
                    Loading -> text "Cargando..."
                    Success lista -> ul [] (List.map viewProyecto lista)
                    Failure _ -> text "Error al conectar con el servidor."
                ]
        _ -> h1 [] [ text "Próximamente..." ]

viewProyecto : Proyecto -> Html Msg
viewProyecto proy =
    li [] [ b [] [ text proy.titulo ], text (" - " ++ proy.tecnologia) ]

urlToRoute : Url.Url -> Route
urlToRoute url =
    case url.path of
        "/" -> Home
        "/portfolio" -> Portfolio
        "/blog" -> Blog
        "/contact" -> Contact
        _ -> NotFound

main : Program () Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }
