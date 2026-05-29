module Main where

import Servant.Elm
import Api (ApiDatos)
import Types ()
import Data.Proxy
import qualified Data.Text.IO as TIO
import qualified Data.Text as T

main :: IO ()
main = do
    let codigoElm = generateElmForAPI (Proxy :: Proxy ApiDatos)
    case codigoElm of
        (x : xs) -> do
            let contenido = T.unlines (x : xs)
            TIO.writeFile "frontend/src/GeneratedApi.elm" contenido
            putStrLn "¡GeneratedApi.elm generado!"
        [] -> putStrLn "Error: no se generó código"
