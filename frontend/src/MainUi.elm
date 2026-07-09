module MainUi exposing (main)

import Browser
import Browser.Navigation as Nav
import Element exposing (Element, centerX, centerY, column, el, fill, height, layout, link, none, padding, paragraph, px, rgb, row, spacing, text, width)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Http
import Styles exposing (..)
import Types exposing (MensajeContacto, PostBlog, Proyecto, blogDecoder, encodeContacto, proyectosDecoder)
import Url



-- Añadimos MensajeContacto
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
                newRoute =
                    urlToRoute url

                cmd =
                    case newRoute of
                        Blog (Just slug) ->
                            getBlogPost slug

                        _ ->
                            Cmd.none
            in
            ( { model | url = url, route = newRoute }, cmd )

        GotProyectos result ->
            case result of
                Ok lista ->
                    ( { model | proyectosStatus = Success lista }, Cmd.none )

                Err error ->
                    ( { model | proyectosStatus = Failure error }, Cmd.none )

        UpdateEmail val ->
            ( { model | contactEmail = val }, Cmd.none )

        UpdateBody val ->
            ( { model | contactBody = val }, Cmd.none )

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
                Ok _ ->
                    ( { model | contactStatus = "¡Enviado!", contactEmail = "", contactBody = "" }, Cmd.none )

                Err _ ->
                    ( { model | contactStatus = "Error al enviar" }, Cmd.none )


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
        [ layout [ width fill, height fill, Background.color (rgb 0.95 0.95 0.95) ]
            (column [ width fill, padding 20, spacing 20 ]
                [ row [ width fill, spacing 10, centerX ]
                    [ viewLink model.route Home "/home" "Home"
                    , viewLink model.route Portfolio "/portfolio" "Portfolio"
                    , viewLink model.route (Blog Nothing) "/blog" "Blog"
                    , viewLink model.route Contact "/contact" "Contacto"
                    ]
                , mainContent model
                ]
            )
        ]
    }


mainContent : Model -> Element Msg
mainContent model =
    case model.route of
        Home ->
            column [ centerX, centerY, spacing 10 ]
                [ el [ Font.size 30, Font.bold ] (text "Bienvenido")
                , paragraph [ width (px 400) ]
                    [ text "Esta es mi página personal construida con Haskell, Servant y Elm." ]
                ]

        Portfolio ->
            column [ width fill, spacing 10 ]
                [ el [ Font.size 24, Font.bold ] (text "Mis Proyectos")
                , case model.proyectosStatus of
                    Loading ->
                        text "Cargando..."

                    Success lista ->
                        column [ spacing 5 ] (List.map viewProyecto lista)

                    Failure _ ->
                        text "Error al conectar con el servidor."
                ]

        Contact ->
            column [ width (px 400), centerX, spacing 10 ]
                [ el [ Font.size 24, Font.bold ] (text "Contacto")
                , Input.text
                    [ width fill ]
                    { onChange = UpdateEmail
                    , text = model.contactEmail
                    , placeholder = Just (Input.placeholder [] (text "Tu Email"))
                    , label = Input.labelAbove [] (text "Email")
                    }
                , Input.multiline
                    [ width fill, height (px 100) ]
                    { onChange = UpdateBody
                    , text = model.contactBody
                    , placeholder = Just (Input.placeholder [] (text "Escribe tu mensaje aquí..."))
                    , label = Input.labelAbove [] (text "Mensaje")
                    , spellcheck = True
                    }
                , Input.button
                    [ Background.color (rgb 0.2 0.4 0.8)
                    , Font.color (rgb 1 1 1)
                    , padding 10
                    ]
                    { onPress = Just SendContacto
                    , label = text "Enviar Mensaje"
                    }
                , el [ Font.color (rgb 0 1 0) ] (text model.contactStatus)
                ]

        Blog maybeSlug ->
            case maybeSlug of
                Nothing ->
                    column [ spacing 10 ]
                        [ el [ Font.size 24, Font.bold ] (text "Blog de Desarrollo")
                        , paragraph [] [ text "Selecciona un artículo:" ]
                        , column [ spacing 5 ]
                            [ link [ Font.color (rgb 0.2 0.4 0.8) ]
                                { url = "/blog/haskell-servant"
                                , label = text "Introducción a Servant"
                                }
                            , link [ Font.color (rgb 0.2 0.4 0.8) ]
                                { url = "/blog/elm-frontend"
                                , label = text "Elm para Haskelleros"
                                }
                            ]
                        ]

                Just slug ->
                    column [ spacing 10 ]
                        [ el [ Font.size 24, Font.bold ] (text ("Leyendo: " ++ slug))
                        , case model.blogStatus of
                            FetchingPost ->
                                text "Cargando post..."

                            PostLoaded post ->
                                paragraph [] [ text post.contenido ]

                            PostError _ ->
                                text "Error al cargar el contenido."

                            _ ->
                                text ""
                        ]

        NotFound ->
            el [ Font.size 30, Font.bold ] (text "404 - No encontrado")


viewProyecto : Proyecto -> Element Msg
viewProyecto proy =
    row [ spacing 5 ]
        [ el [ Font.bold ] (text proy.titulo)
        , text (" - " ++ proy.tecnologia)
        ]


urlToRoute : Url.Url -> Route
urlToRoute url =
    let
        pathSegments =
            String.split "/" url.path |> List.filter (not << String.isEmpty)
    in
    case pathSegments of
        [] ->
            Home

        [ "home" ] ->
            Home

        [ "portfolio" ] ->
            Portfolio

        [ "contact" ] ->
            Contact

        [ "blog" ] ->
            Blog Nothing

        [ "blog", slug ] ->
            Blog (Just slug)

        -- Captura /blog/lo-que-sea
        _ ->
            NotFound


viewLink : Route -> Route -> String -> String -> Element Msg
viewLink currentRoute targetRoute path label =
    let
        isActive =
            currentRoute == targetRoute

        attrs =
            [ Font.color
                (if isActive then
                    rgb 0 0 0

                 else
                    rgb 0.2 0.4 0.8
                )
            ]
                ++ (if isActive then
                        [ Font.bold, Font.underline ]

                    else
                        []
                   )
    in
    link attrs
        { url = path
        , label = text label
        }


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
