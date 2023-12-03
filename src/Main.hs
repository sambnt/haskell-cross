{-# LANGUAGE LambdaCase #-}

module Main where

-- import qualified Graphics.UI.GLFW as GLFW
import Control.Monad (when)
import Control.Concurrent (threadDelay)
import Control.Exception (bracket)
import Vulkan.Core10.Enums.PipelineBindPoint (PipelineBindPoint(PipelineBindPoint))

main = do
  let x = PipelineBindPoint 0
  putStrLn $ "hello world " <> show x

-- main = do
--   withWindow 800 600 "Hello World" $ \win -> do
--     threadDelay 1000000

-- -- withWindow :: Natural -> Natural -> String -> (GLFW.Window -> IO ()) -> IO ()
-- withWindow width height title f =
--   bracket
--     GLFW.init
--     (const GLFW.terminate)
--     (\succeeded -> when succeeded $ do
--       -- Don't use an OpenGL API
--       GLFW.windowHint $ GLFW.WindowHint'ClientAPI GLFW.ClientAPI'NoAPI
--       -- Resizing takes extra work
--       GLFW.windowHint $ GLFW.WindowHint'Resizable True
--       bracket
--         (GLFW.createWindow (fromIntegral width) (fromIntegral height) title Nothing Nothing)
--         (\case
--             (Just win) -> GLFW.destroyWindow win
--             Nothing -> pure ()
--         )
--         (\mWin ->
--           case mWin of
--             Nothing -> do
--               err <- GLFW.getError
--               print err
--             (Just win) -> do
--               GLFW.setErrorCallback $ Just simpleErrorCallback
--               f win
--         )
--     )
--   where
--     simpleErrorCallback e s =
--         putStrLn $ unwords [show e, show s]
