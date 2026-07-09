module Styles exposing (..)

import Css exposing (..)
import Css.Global exposing (global, body, html)
import Html.Styled as Styled exposing (Html, styled, div, text, h1, p)
import Html.Styled.Attributes exposing (css)

-- 1. VARIABLES (paleta de colores)
primaryColor : Color
primaryColor = hex "2c3e50"

secondaryColor : Color
secondaryColor = hex "3498db"

backgroundColor : Color
backgroundColor = hex "ecf0f1"

textColor : Color
textColor = hex "2c3e50"

-- 2. ESTILOS REUTILIZABLES
navStyle : Style
navStyle =
    batch
        [ Css.backgroundColor (hex "2c3e50")
        , padding (px 10)
        , displayFlex
        , justifyContent center
        , alignItems center
        ]
        
navLinkStyle : Style
navLinkStyle =
    batch
        [ color (hex "ecf0f1")
        , margin2 (px 0) (px 15)
        , textDecoration none
        , fontSize (px 16)
        , hover [ color secondaryColor ]
        ]

sectionTitleStyle : Style
sectionTitleStyle =
    batch
        [ color primaryColor
        , fontSize (px 28)
        , textAlign center
        , marginBottom (px 20)
        ]
