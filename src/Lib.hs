{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Lib
    ( startApp
    , app
    , PaginaPersonalAPI
    ) where

import Data.Aeson
import Data.Aeson (ToJSON, FromJSON)
import Data.Text (Text)
import Network.Wai (Application)
import Network.Wai.Handler.Warp (run)
import Servant
import GHC.Generics (Generic)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader
import Servant.Server.StaticFiles (serveDirectoryWebApp)
import Servant.HTML.Lucid
import Lucid
import Servant.Client
import Data.Proxy
import Data.OpenApi (OpenApi, ToSchema)
import Servant.OpenApi (toOpenApi)
import Database.SQLite.Simple hiding ((:.))
import Servant.Auth.Server
import Network.Wai.Middleware.Cors (simpleCors)
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import Servant.Server.Internal
import Types
import Api
import Handlers
import System.Environment (lookupEnv)
import Network.Wai.Middleware.RequestLogger (logStdout, logStdoutDev)

data Trazabilidad

instance HasServer api context => HasServer (Trazabilidad :> api) context where
  -- 1. ¿Qué firma tendrá el Handler? 
  -- Respuesta: La misma que tenga el resto del API. No le pasamos parámetros extra al handler.
  type ServerT (Trazabilidad :> api) m = ServerT api m

  -- 2. ¿Cómo procesa la petición HTTP a nivel de WAI?
  route Proxy context subserver = 
    -- Aquí podrías inspeccionar la petición (request) y fallar con `delayedFailFatal`
    -- o simplemente dejar que la petición continúe hacia el siguiente combinador:
    route (Proxy :: Proxy api) context subserver
   --  hoistServerWithContext _ Proxy nt = hoistServerWithContext (Proxy :: Proxy api) Proxy nt

-- 3. Implementacion del servidor

-- Convierte nuestro AppM en el Handler que Servant necesita
nt :: Config -> AppM a -> Handler a
nt config app = runReaderT app config

server :: Config -> Server PaginaPersonalAPI
server cfg = 
    (healthCheck :<|> miHome :<|> servirEstaticos :<|> servirSwagger)
    :<|> hoistServer (Proxy :: Proxy ApiDatos) (nt cfg) apiDatosServerAppM
    :<|> hoistServerWithContext (Proxy :: Proxy ApiAdmin) (Proxy :: Proxy '[CookieSettings, JWTSettings]) (nt cfg) adminServerAppM

-- Creamos la application de WAI a partir de nuestro servidor Servant
app :: Config -> CookieSettings -> JWTSettings -> Application
app cfg cookieCfg jwtCfg = 
    let contexto = cookieCfg :. jwtCfg :. EmptyContext
    in serveWithContext (Proxy :: Proxy PaginaPersonalAPI) contexto (server cfg)

-- Servant genera las funciones de cliente mágicamente.
pedirPortfolio :<|> enviarContacto :<|> pedirBlog 
  = client (Proxy :: Proxy ApiDatos)

-- En tu Main/startApp creamos la configuración inicial
startApp :: IO ()
startApp = do
    maybePort <- lookupEnv "PORT"
    let port = case maybePort of
          Just p  -> read p
          Nothing -> 8080
    
    maybeDbUrl <- lookupEnv "DATABASE_URL"
    let dbPath = case maybeDbUrl of
          Just p  -> p
          Nothing -> "/tmp/mi_base_de_datos.sqlite"
    
    putStrLn $ "Abriendo base de datos: " ++ dbPath
    conn <- open dbPath
    
    execute_ conn "CREATE TABLE IF NOT EXISTS proyectos (id INTEGER PRIMARY KEY, titulo TEXT, tecnologia TEXT)"
    execute_ conn "INSERT OR IGNORE INTO proyectos (id, titulo, tecnologia) VALUES (1, 'Mi Web en Haskell', 'Servant + SQLite')"
    
    miLlave <- generateKey
    let jwtCfg = defaultJWTSettings miLlave
    let cookieCfg = defaultCookieSettings

    let yoMismo = Admin "Yago"
    tokenGenerado <- makeJWT yoMismo jwtCfg Nothing
    case tokenGenerado of
      Right t  -> putStrLn $ "\n=== TU TOKEN SECRETO ===\n" ++ show t ++ "\n========================\n"
      Left err -> putStrLn "Error creando token"

    let miConfig = Config "Producción" conn
    let appConLog = logStdoutDev $ simpleCors $ app miConfig cookieCfg jwtCfg
    putStrLn $ "Arrancando servidor en puerto " ++ show port
    run port appConLog
