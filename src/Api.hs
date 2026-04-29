{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Api where

import Servant
import Servant.HTML.Lucid (HTML)
import Lucid (Html)
import Data.Text (Text)
import Data.OpenApi (OpenApi)
import Servant.Auth.Server (Auth, JWT)
import Types -- Importamos nuestros modelos

type ApiDatos =
       "portfolio" :> Get '[JSON] [Proyecto]
  :<|> "contacto" :> ReqBody '[JSON] MensajeContacto :> Post '[JSON] NoContent
  :<|> "blog" :> Capture "slug" Text :> Get '[JSON] PostBlog

type ApiUI =
       "home" :> Get '[HTML] (Html ())
  :<|> "assets" :> Raw
  :<|> "swagger.json" :> Get '[JSON] OpenApi

type ApiAdmin = 
  "admin" :> "portfolio" :> Auth '[JWT] Admin :> ReqBody '[JSON] Proyecto :> Post '[JSON] NoContent

type PaginaPersonalAPI = ApiUI :<|> ApiDatos :<|> ApiAdmin
