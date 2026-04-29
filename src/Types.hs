{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}

module Types where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import Database.SQLite.Simple (Connection, FromRow(..), field)
import Servant (Handler)
import Control.Monad.Reader (ReaderT)
import Servant.Auth.Server (ToJWT, FromJWT)
import Data.OpenApi (ToSchema)

-- Modelos
data Proyecto = Proyecto { idProy :: Int, titulo :: Text, tecnologia :: Text } 
  deriving (Generic, Show)
instance ToJSON Proyecto
instance FromJSON Proyecto
instance ToSchema Proyecto
instance FromRow Proyecto where
  fromRow = Proyecto <$> field <*> field <*> field

data MensajeContacto = MensajeContacto { email :: Text, cuerpo :: Text }
  deriving (Generic, Show)
instance ToJSON MensajeContacto
instance FromJSON MensajeContacto
instance ToSchema MensajeContacto

data PostBlog = PostBlog { contenido :: Text }
  deriving (Generic, Show)
instance ToJSON PostBlog
instance FromJSON PostBlog
instance ToSchema PostBlog

data Admin = Admin { nombreAdmin :: Text } deriving (Generic, Show)
instance ToJSON Admin
instance FromJSON Admin
instance ToJWT Admin
instance FromJWT Admin

-- Configuración y Monad
data Config = Config { entorno :: String, dbConn :: Connection }
type AppM = ReaderT Config Handler
