{-# LANGUAGE RecordWildCards #-}

module FourBar
  ( Linkage(..)
  , Pose(..)
  , Point
  , eps
  , clamp
  , normalizeAngle
  , toDegrees
  , excesses
  , grashofIndex
  , validityIndex
  , isAssemblable
  , isGrashof
  , signTriple
  , classifyMotion
  , basicMotionState
  , solvePose
  , nearestValidAlpha
  ) where

import Data.Fixed (mod')
import Data.List (isInfixOf, minimumBy, sort)
import Data.Maybe (isJust)
import Data.Ord (comparing)

-- | Cartesian point in centimeters in the mechanism coordinate frame.
-- A = (0,0), B = (g,0).
type Point = (Double, Double)

-- | Four-bar linkage lengths in centimeters.
data Linkage = Linkage
  { groundLink   :: Double  -- ^ g: fixed ground link AB
  , inputLink    :: Double  -- ^ a: input link AC
  , outputLink   :: Double  -- ^ b: output link BD
  , floatingLink :: Double  -- ^ f: coupler/floating link CD
  } deriving (Eq, Show)

-- | One assembled geometric pose of the linkage.
data Pose = Pose
  { pointA   :: Point
  , pointB   :: Point
  , pointC   :: Point
  , pointD   :: Point
  , alphaRad :: Double
  , betaRad  :: Double
  } deriving (Eq, Show)

eps :: Double
eps = 1.0e-7

clamp :: Double -> Double -> Double -> Double
clamp lo hi x = max lo (min hi x)

normalizeAngle :: Double -> Double
normalizeAngle x =
  let tau = 2 * pi
      y   = x `mod'` tau
  in if y < 0 then y + tau else y

toDegrees :: Double -> Double
toDegrees x = 180 * x / pi

-- | Excess quantities from the Illinois Dynamics Reference convention:
-- T1 = g + f - b - a
-- T2 = b + g - f - a
-- T3 = f + b - g - a
excesses :: Linkage -> (Double, Double, Double)
excesses Linkage{..} =
  ( groundLink + floatingLink - outputLink - inputLink
  , outputLink + groundLink - floatingLink - inputLink
  , floatingLink + outputLink - groundLink - inputLink
  )

sortedLengths :: Linkage -> [Double]
sortedLengths Linkage{..} = sort [groundLink, inputLink, outputLink, floatingLink]

-- | G = s + l - p - q, where s and l are the shortest and longest links.
-- With this sign convention, the classical Grashof condition is G <= 0.
grashofIndex :: Linkage -> Double
grashofIndex linkage =
  case sortedLengths linkage of
    [s, p, q, l] -> s + l - p - q
    _            -> 0

-- | V = l - s - p - q. The assembly is possible only when V <= 0.
validityIndex :: Linkage -> Double
validityIndex linkage =
  case sortedLengths linkage of
    [s, p, q, l] -> l - s - p - q
    _            -> 0

isAssemblable :: Linkage -> Bool
isAssemblable linkage = validityIndex linkage <= eps

isGrashof :: Linkage -> Bool
isGrashof linkage = isAssemblable linkage && grashofIndex linkage <= eps

signCode :: Double -> Char
signCode x
  | abs x <= 1.0e-6 = '0'
  | x > 0           = '+'
  | otherwise       = '-'

signTriple :: Linkage -> String
signTriple linkage =
  let (t1, t2, t3) = excesses linkage
  in [signCode t1, signCode t2, signCode t3]

-- | Motion classification using the full-linkage-model table. The labels
-- include the special 0-rocker and π-rocker cases.
classifyMotion :: Linkage -> (String, String)
classifyMotion linkage =
  case signTriple linkage of
    "+++" -> ("crank",    "rocker")
    "++0" -> ("crank",    "π-rocker")
    "++-" -> ("0-rocker", "π-rocker")

    "0++" -> ("crank",    "π-rocker")
    "0+0" -> ("crank",    "π-rocker")
    "0+-" -> ("0-rocker", "π-rocker")

    "-++" -> ("π-rocker", "π-rocker")
    "-+0" -> ("π-rocker", "π-rocker")
    "-+-" -> ("rocker",   "rocker")

    "+0+" -> ("crank",    "0-rocker")
    "+00" -> ("crank",    "crank")
    "+0-" -> ("0-rocker", "crank")

    "00+" -> ("crank",    "crank")
    "000" -> ("crank",    "crank")
    "00-" -> ("0-rocker", "crank")

    "-0+" -> ("crank",    "crank")
    "-00" -> ("crank",    "crank")
    "-0-" -> ("0-rocker", "0-rocker")

    "+-+" -> ("π-rocker", "0-rocker")
    "+-0" -> ("π-rocker", "crank")
    "+--" -> ("rocker",   "crank")

    "0-+" -> ("crank",    "crank")
    "0-0" -> ("crank",    "crank")
    "0--" -> ("0-rocker", "crank")

    "--+" -> ("crank",    "crank")
    "--0" -> ("crank",    "crank")
    "---" -> ("0-rocker", "0-rocker")

    _     -> ("unknown", "unknown")

plainMotion :: String -> String
plainMotion s
  | "crank" `isInfixOf` s = "crank"
  | "rocker" `isInfixOf` s = "rocker"
  | otherwise = "unknown"

-- | Collapsed state requested in most mechanism-design courses:
-- crank-crank, crank-rocker, rocker-rocker, or rocker-crank.
basicMotionState :: Linkage -> String
basicMotionState linkage =
  let (i, o) = classifyMotion linkage
  in plainMotion i ++ " - " ++ plainMotion o

solvePose :: Int -> Linkage -> Double -> Maybe Pose
solvePose branch linkage@Linkage{..} rawAlpha
  | not (isAssemblable linkage) = Nothing
  | d <= eps                    = Nothing
  | d > floatingLink + outputLink + eps = Nothing
  | d < abs (floatingLink - outputLink) - eps = Nothing
  | otherwise =
      let aDist = (floatingLink * floatingLink - outputLink * outputLink + d * d) / (2 * d)
          h2    = floatingLink * floatingLink - aDist * aDist
          h     = sqrt (max 0 h2)
          ux    = dx / d
          uy    = dy / d
          px    = cx + aDist * ux
          py    = cy + aDist * uy
          orient = if branch >= 0 then 1 else -1
          ddx   = px + orient * h * (-uy)
          ddy   = py + orient * h * ux
          beta  = normalizeAngle (atan2 ddy (ddx - groundLink))
      in Just Pose
          { pointA = (0, 0)
          , pointB = (groundLink, 0)
          , pointC = (cx, cy)
          , pointD = (ddx, ddy)
          , alphaRad = alpha
          , betaRad = beta
          }
  where
    alpha = normalizeAngle rawAlpha
    cx = inputLink * cos alpha
    cy = inputLink * sin alpha
    dx = groundLink - cx
    dy = 0 - cy
    d  = sqrt (dx * dx + dy * dy)

angularDistance :: Double -> Double -> Double
angularDistance a b =
  let tau = 2 * pi
      d = abs (normalizeAngle (a - b))
  in min d (tau - d)

-- | Find the nearest sampled input angle that produces a valid assembly.
nearestValidAlpha :: Int -> Linkage -> Double -> Maybe Double
nearestValidAlpha branch linkage current =
  let samples = [2 * pi * fromIntegral k / 720 | k <- [0 :: Int .. 719]]
      valids  = filter (isJust . solvePose branch linkage) samples
  in case valids of
       [] -> Nothing
       xs -> Just (minimumBy (comparing (angularDistance current)) xs)
