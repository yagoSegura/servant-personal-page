module Types exposing (..)

import Json.Decode as Decode exposing (Decoder, field, int, string, list)

-- 1. MODELOS (Iguales a Types.hs)
type alias Proyecto =
    { idProy : Int
    , titulo : String
    , tecnologia : String
    }

type alias PostBlog =
    { contenido : String }

-- 2. DECODERS (Cómo convertir JSON de Servant a Elm)
proyectoDecoder : Decoder Proyecto
proyectoDecoder =
    Decode.map3 Proyecto
        (field "idProy" int)
        (field "titulo" string)
        (field "tecnologia" string)

proyectosDecoder : Decoder (List Proyecto)
proyectosDecoder =
    Decode.list proyectoDecoder

blogDecoder : Decoder PostBlog
blogDecoder =
    Decode.map PostBlog
        (field "contenido" string)
