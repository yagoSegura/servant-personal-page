getPortfolio : (Result Http.Error  ((List Proyecto))  -> msg) -> Cmd msg
getPortfolio toMsg =
    let
        params =
            List.filterMap identity
            (List.concat
                [])
    in
        Http.request
            { method =
                "GET"
            , headers =
                []
            , url =
                Url.Builder.crossOrigin ""
                    [ "portfolio"
                    ]
                    params
            , body =
                Http.emptyBody
            , expect =
                Http.expectJson toMsg (Json.Decode.list (jsonDecProyecto))
            , timeout =
                Nothing
            , tracker =
                Nothing
            }

postContacto : MensajeContacto -> (Result Http.Error  (NoContent)  -> msg) -> Cmd msg
postContacto body toMsg =
    let
        params =
            List.filterMap identity
            (List.concat
                [])
    in
        Http.request
            { method =
                "POST"
            , headers =
                []
            , url =
                Url.Builder.crossOrigin ""
                    [ "contacto"
                    ]
                    params
            , body =
                Http.jsonBody (jsonEncMensajeContacto body)
            , expect =
                Http.expectJson toMsg jsonDecNoContent
            , timeout =
                Nothing
            , tracker =
                Nothing
            }

getBlogBySlug : String -> (Result Http.Error  (PostBlog)  -> msg) -> Cmd msg
getBlogBySlug capture_slug toMsg =
    let
        params =
            List.filterMap identity
            (List.concat
                [])
    in
        Http.request
            { method =
                "GET"
            , headers =
                []
            , url =
                Url.Builder.crossOrigin ""
                    [ "blog"
                    , (capture_slug)
                    ]
                    params
            , body =
                Http.emptyBody
            , expect =
                Http.expectJson toMsg jsonDecPostBlog
            , timeout =
                Nothing
            , tracker =
                Nothing
            }
