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
-- Pasamos la config desde arriba
server :: Config -> Server PaginaPersonalAPI
server cfg = apiUIServer 
        :<|> hoistServer (Proxy :: Proxy ApiDatos) (nt cfg) apiDatosServerAppM 
        :<|> hoistServerWithContext (Proxy :: Proxy ApiAdmin) (Proxy :: Proxy '[CookieSettings, JWTSettings]) (nt cfg) adminServer

  where
    apiUIServer = miHome :<|> servirEstaticos :<|> servirSwagger
    
    -- LA MAGIA: hoistServer recorre todo tu API y aplica el traductor 'nt'
    apiDatosServer :: Server ApiDatos
    apiDatosServer = hoistServer (Proxy :: Proxy ApiDatos) (nt cfg) apiDatosServerAppM

    adminServer :: ServerT ApiAdmin AppM
    adminServer = crearProyectoProtegido
    
    
-- Actualizamos el WAI App
-- Añadimos las configuraciones de JWT al WAI app
app :: Config -> CookieSettings -> JWTSettings -> Application
app cfg cookieCfg jwtCfg = 
    let contexto = cookieCfg :. jwtCfg :. EmptyContext
    in serveWithContext (Proxy :: Proxy PaginaPersonalAPI) contexto (server cfg)



-- En tu Main/startApp creamos la configuración inicial
startApp :: IO ()
startApp = do
    -- Leer puerto desde variable de entorno, o usar 8080 por defecto
    maybePort <- lookupEnv "PORT"
    let port = case maybePort of
          Just p  -> read p
          Nothing -> 8080
    
    -- Leer ruta de la BD desde variable de entorno
    maybeDbUrl <- lookupEnv "DATABASE_URL"
    let dbPath = case maybeDbUrl of
          Just p  -> p
          Nothing -> "/tmp/mi_base_de_datos.sqlite"
    
    putStrLn $ "Abriendo base de datos: " ++ dbPath
    conn <- open dbPath
    
    -- Creamos la tabla y un dato inicial
    execute_ conn "CREATE TABLE IF NOT EXISTS proyectos (id INTEGER PRIMARY KEY, titulo TEXT, tecnologia TEXT)"
    execute_ conn "INSERT OR IGNORE INTO proyectos (id, titulo, tecnologia) VALUES (1, 'Mi Web en Haskell', 'Servant + SQLite')"
    
        -- 1. Generamos llave criptográfica y configuraciones
    miLlave <- generateKey
    let jwtCfg = defaultJWTSettings miLlave
    let cookieCfg = defaultCookieSettings

    -- 2. Creamos un token falso para ti y lo imprimimos
    let yoMismo = Admin "Yago"
    tokenGenerado <- makeJWT yoMismo jwtCfg Nothing
    case tokenGenerado of
      Right t  -> putStrLn $ "\n=== TU TOKEN SECRETO ===\n" ++ show t ++ "\n========================\n"
      Left err -> putStrLn "Error creando token"

    let miConfig = Config "Producción" conn -- tu config de antes
    let port = 8080

    -- putStrLn $ "Arrancando servidor en puerto " ++ show port
    
    -- 3. Le pasamos todo a WAI
    -- run port $ logStdoutDev $ simpleCors $ app miConfig cookieCfg jwtCfg

    putStrLn $ "Arrancando servidor en puerto " ++ show port
    run port (app miConfig cookieCfg jwtCfg)




-- Fíjate en ServerT. Significa: "Un servidor para ApiDatos, pero corriendo en AppM"
--apiDatosServerAppM :: ServerT ApiDatos AppM
--apiDatosServerAppM = obtenerProyectos :<|> recibirContacto :<|> leerPost

--  where
    -- Fíjate: ¡Ahora usamos AppM!
--    obtenerProyectos :: AppM [Proyecto]
--    obtenerProyectos = do
--      conf <- ask
--      let conexion = dbConn conf

--      liftIO $ putStrLn "Haciendo SELECT a la base de datos..."
      -- Ejecutamos la consulta. 'query_' infiere que devuelve [Proyecto] por la firma de la función.
--      proyectosDB <- liftIO $ query_ conexion "SELECT id, titulo, tecnologia FROM proyectos"
--      return proyectosDB
      
    -- (Cambia también recibirContacto y leerPost para que devuelvan AppM)
--    recibirContacto :: MensajeContacto -> AppM NoContent
--    recibirContacto m = return NoContent
    
--    leerPost :: Text -> AppM PostBlog
--    leerPost slug = do
      -- Simulamos lógica de negocio: si piden el post "secreto", damos un 404
--      if slug == "secreto"
--        then throwError err404 { errBody = "El post que buscas no existe o es privado" }
--        else return $ PostBlog ("Contenido del post: " <> slug)

    
-- 4. Funciones de exportacion
-- Creamos la application de WAI a partir de nuestro servidor Servant

-- Convierte nuestro AppM en el Handler que Servant necesita
nt :: Config -> AppM a -> Handler a
nt config app = runReaderT app config


-- Servant genera las funciones de cliente mágicamente.
-- Usamos el mismo patrón `:<|>` para desestructurar las funciones generadas.
pedirPortfolio :<|> enviarContacto :<|> pedirBlog 
  = client (Proxy :: Proxy ApiDatos)
