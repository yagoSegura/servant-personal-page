module MainStyled exposing (main)

import Browser
import Browser.Navigation as Nav
import Styles exposing (..)
import Http
import Url
import Types exposing (Proyecto, proyectosDecoder, MensajeContacto, encodeContacto, PostBlog, blogDecoder) -- Añadimos MensajeContacto
import Html exposing (Html, div, text, h1, p, ul, li, a, button, input, textarea, nav, span, b)
import Html.Attributes exposing (href, placeholder, value, style)
import Html.Events exposing (onClick, onInput)



-- 1. MODELO
type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , route : Route
    , proyectosStatus : Status
    , contactEmail : String
    , contactBody : String
    , contactStatus : String
    , blogStatus : BlogStatus
    }

type Status
    = Loading
    | Success (List Proyecto)
    | Failure Http.Error

type BlogStatus
    = NoPost
    | FetchingPost
    | PostLoaded PostBlog
    | PostError Http.Error
    | SuccessPost PostBlog
    | FailurePost Http.Error 
      
type Route
    = Home
    | Portfolio
    | Blog (Maybe String)
    | Contact
    | NotFound

-- 2. INIT
init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
-- init : () -> ( Model, Cmd Msg ) -> Esta opcion Browsr.Document . mirar main
init _ url key =
    ( { key = key
      , url = url
      , route = urlToRoute url
      , proyectosStatus = Loading
      , contactEmail = ""
      , contactBody = ""
      , contactStatus = ""
      , blogStatus = NoPost
      }
    , getProyectos
    )

-- 3. MENSAJES (UNIFICADO)
type Msg
    = ChangedUrl Url.Url
    | ClickedLink Browser.UrlRequest
    | GotProyectos (Result Http.Error (List Proyecto))
    | UpdateEmail String
    | UpdateBody String
    | SendContacto
    | ContactResult (Result Http.Error ())
    | GotBlogPost (Result Http.Error PostBlog)

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
          let
              newRoute = urlToRoute url
              cmd =
                  case newRoute of
                      Blog (Just slug) -> getBlogPost slug
                      _ -> Cmd.none
          in
          ( { model | url = url, route = newRoute }, cmd )

        GotProyectos result ->
            case result of
                Ok lista ->
                    ( { model | proyectosStatus = Success lista }, Cmd.none )
                Err error ->
                    ( { model | proyectosStatus = Failure error }, Cmd.none )
        UpdateEmail val -> ( { model | contactEmail = val }, Cmd.none )
        UpdateBody val -> ( { model | contactBody = val }, Cmd.none )
        GotBlogPost result ->
            case result of
                Ok post ->
                    ( { model | blogStatus = SuccessPost post }, Cmd.none )

                Err error ->
                    ( { model | blogStatus = FailurePost error }, Cmd.none )

        SendContacto -> 
            ( model, postContacto { email = model.contactEmail, cuerpo = model.contactBody } )
        ContactResult result ->
            case result of
                Ok _ -> ( { model | contactStatus = "¡Enviado!", contactEmail = "", contactBody = "" }, Cmd.none )
                Err _ -> ( { model | contactStatus = "Error al enviar"}, Cmd.none )

postContacto : MensajeContacto -> Cmd Msg
postContacto msg =
            Http.post
                { url = "http://localhost:8080/contacto"
                , body = Http.jsonBody (encodeContacto msg)
                , expect = Http.expectWhatever ContactResult
                }

getBlogPost : String -> Cmd Msg
getBlogPost slug =
    Http.get
        { url = "http://localhost:8080/blog/" ++ slug
        , expect = Http.expectJson GotBlogPost blogDecoder
        }

        
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
        [ nav [ style "background" "#f4f4f4", style "padding" "10px" ]
            [ ul [ style "list-style" "none", style "padding" "0" ]
                [ viewLink model.route Home "/home" "Home"
                , viewLink model.route Portfolio "/portfolio" "Portfolio"
                , viewLink model.route (Blog Nothing) "/blog" "Blog"
                , viewLink model.route Contact "/contact" "Contacto"
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
        Contact ->
            div [ style "padding" "20px" ]
                [ h1 [] [ text "Contacto" ]
                , input 
                    [ placeholder "Tu Email"
                    , value model.contactEmail
                    , onInput UpdateEmail 
                    , style "display" "block"
                    , style "margin-bottom" "10px"
                    ] 
                    []
                , textarea 
                    [ placeholder "Escribe tu mensaje aquí..."
                    , value model.contactBody
                    , onInput UpdateBody
                    , style "display" "block"
                    , style "width" "300px"
                    , style "height" "100px"
                    ] 
                    []
                , button 
                    [ onClick SendContacto
                    , style "margin-top" "10px"
                    ] 
                    [ text "Enviar Mensaje" ]
                , p [ style "color" "#00FF00" ] 
                    [ text model.contactStatus ]
                ]
                
        Blog maybeSlug ->
            case maybeSlug of
                Nothing ->
                    div [] 
                        [ h1 [] [ text "Blog de Desarrollo" ]
                        , p [] [ text "Selecciona un artículo:" ]
                        , ul [] 
                            [ li [] [ a [ href "/blog/haskell-servant" ] [ text "Introducción a Servant" ] ]
                            , li [] [ a [ href "/blog/elm-frontend" ] [ text "Elm para Haskelleros" ] ]
                            ]
                        ]

                Just slug ->
                    div []
                        [ h1 [] [ text ("Leyendo: " ++ slug) ]
                        , case model.blogStatus of
                            FetchingPost -> text "Cargando post..."
                            PostLoaded post -> p [] [ text post.contenido ]
                            PostError _ -> text "Error al cargar el contenido."
                            _ -> text ""
                        ]

        NotFound -> 
            h1 [] [ text "404 - No encontrado" ]

viewContacto : Model -> Html Msg
viewContacto model =
    div [ style "padding" "20px" ]
        [ h1 [] [ text "Contacto" ]
        , input
              [ placeholder "Email"
              , value model.contactEmail
              , onInput UpdateEmail
              , style "display" "block"
              ]
              []
        , textarea
              [ placeholder "Mensaje"
              , value model.contactBody
              , onInput UpdateBody
              , style "display" "block"
              , style "height" "100px"
              ]
              []
         , button
              [ onClick SendContacto ]
              [ text "Enviar" ]
         , p  [ style "color" "#00FF00" ]
              [ text model.contactStatus ]
         ]


viewProyecto : Proyecto -> Html Msg
viewProyecto proy =
    li [] [ b [] [ text proy.titulo ], text (" - " ++ proy.tecnologia) ]

urlToRoute : Url.Url -> Route
urlToRoute url =
    let
        pathSegments = String.split "/" url.path |> List.filter (not << String.isEmpty)
    in
    case pathSegments of
        [] -> Home
        [ "home" ] -> Home
        [ "portfolio" ] -> Portfolio
        [ "contact" ] -> Contact
        [ "blog" ] -> Blog Nothing
        [ "blog", slug ] -> Blog (Just slug) -- Captura /blog/lo-que-sea
        _ -> NotFound


viewLink : Route -> Route -> String -> String -> Html Msg
viewLink currentRoute targetRoute path label =
    li [ style "display" "inline", style "margin-right" "20px" ]
        [ a 
            [ href path
            , style "font-weight" (if currentRoute == targetRoute then "bold" else "normal")
            , style "text-decoration" (if currentRoute == targetRoute then "underline" else "none")
            ] 
            [ text label ]
        ]

        
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
