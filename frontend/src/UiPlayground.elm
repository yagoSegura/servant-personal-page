module UiPlayground exposing (main)

import Element exposing (..)
import Element.Background as Background
import Element.Font as Font


main =
    layout [ Background.color (rgb 0.95 0.95 0.95) ]
        (column [ width fill, padding 20, spacing 20 ]
            [ text "Mi Página Personal"
                |> el [ Font.size 30, Font.bold, centerX ]
            , row [ width fill, spacing 10, centerX ]
                [ link [ Font.color (rgb 0.2 0.4 0.8) ] { url = "/home", label = text "Home" }
                , link [] { url = "/portfolio", label = text "Portfolio" }
                , link [] { url = "/blog", label = text "Blog" }
                ]
            , paragraph [ width (px 400), centerX ]
                [ text "Bienvenido a mi web personal. Esto está hecho con elm-ui." ]
            ]
        )
