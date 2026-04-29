{-# LANGUAGE OverloadedStrings #-} -- Muy importante para los textos de error

module Handlers (
    crearProyectoProtegido,
    adminServerAppM,
    apiDatosServerAppM,
    miHome,
    servirEstaticos,
    servirSwagger,
)where

import Servant
import Control.Monad.Reader (ask)
import Control.Monad.IO.Class (liftIO)
import Data.Text (Text)
import Database.SQLite.Simple (query_)
import Lucid (Html, html_, head_, title_, body_, h1_, p_, link_, rel_, type_, href_)
import Servant.HTML.Lucid (HTML)
import Servant.Server.StaticFiles (serveDirectoryWebApp)
import Servant.OpenApi (toOpenApi)
import Servant (Handler)
import Servant (Tagged)
import Network.Wai (Application)
import Data.OpenApi (OpenApi)
import Api (ApiDatos)
import Data.Proxy (Proxy(..))
import Servant.Auth.Server (AuthResult(..))
import Servant (ServerT, (:<|>)(..))

-- TUS PROPIOS MÓDULOS (La clave)
import Types
import Api 


-- Fíjate: ¡Ahora usamos AppM!
obtenerProyectos :: AppM [Proyecto]
obtenerProyectos = do
  conf <- ask
  let conexion = dbConn conf

  liftIO $ putStrLn "Haciendo SELECT a la base de datos..."
  -- Ejecutamos la consulta. 'query_' infiere que devuelve [Proyecto] por la firma de la función.
  proyectosDB <- liftIO $ query_ conexion "SELECT id, titulo, tecnologia FROM proyectos"
  return proyectosDB
      
-- (Cambia también recibirContacto y leerPost para que devuelvan AppM)
recibirContacto :: MensajeContacto -> AppM NoContent
recibirContacto m = return NoContent
    
leerPost :: Text -> AppM PostBlog
leerPost slug = do
  -- Simulamos lógica de negocio: si piden el post "secreto", damos un 404
  if slug == "secreto"
    then throwError err404 { errBody = "El post que buscas no existe o es privado" }
    else return $ PostBlog ("Contenido del post: " <> slug)

miHome :: Handler (Html ())
miHome = return $ do
    html_ $ do
        head_ $ do
          title_ "Mi Página Personal"
          link_ [rel_ "stylesheet", type_ "text/css", href_ "/assets/estilo.css"]
        body_ $ do
          h1_ "Bienvenido a mi web"
          p_ "Renderizado tipo-seguro desde Servant y Emacs."


-- Manejador de estaticos
servirEstaticos :: Tagged Handler Application
servirEstaticos = serveDirectoryWebApp "static"

--swagger
servirSwagger :: Handler OpenApi
servirSwagger = return (toOpenApi (Proxy :: Proxy ApiDatos))

-- El AuthResult te lo inyecta Servant mágicamente
crearProyectoProtegido :: AuthResult Admin -> Proyecto -> AppM NoContent
crearProyectoProtegido (Authenticated admin) nuevoProy = do
   liftIO $ putStrLn $ "¡" ++ show (nombreAdmin admin) ++ " está creando un proyecto!"
   -- Aquí harías el INSERT a SQLite...
   return NoContent
crearProyectoProtegido _ _ = throwError err401 -- Si falla, lanzamos 401

-- 1. Agrupador de la API de Datos
apiDatosServerAppM :: ServerT ApiDatos AppM
apiDatosServerAppM = obtenerProyectos :<|> recibirContacto :<|> leerPost

-- 2. Agrupador de la API de Administración
adminServerAppM :: ServerT ApiAdmin AppM
adminServerAppM = crearProyectoProtegido
