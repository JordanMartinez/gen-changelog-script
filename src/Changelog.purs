module Changelog where

import Prelude

import Affjax as AX
import Affjax.RequestHeader as AXRH
import Affjax.ResponseFormat as RF
import Affjax.StatusCode as AXSC
import Data.Array (filter, null)
import Data.Codec (decode)
import Data.Codec.Argonaut (JsonCodec, array, printJsonDecodeError)
import Data.Codec.Argonaut as CA
import Data.Codec.Argonaut.Record as CAR
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Monoid (power)
import Data.String (Pattern(..))
import Data.String.CodeUnits (drop, indexOf, length, takeWhile)
import Data.String.Common (joinWith, trim)
import Data.String.Utils (lines)
import Effect.Aff (Aff, error, throwError)
import Effect.Class.Console (log)
import Data.Codec.Argonaut.Compat as Compat

type ReleaseInfo =
  { tag_name :: String
  , html_url :: String
  , body :: Maybe String
  , published_at :: String
  , draft :: Boolean
  }

releaseCodec :: JsonCodec ReleaseInfo
releaseCodec =
  CAR.object "ReleaseInfo" $
    { tag_name: CA.string
    , html_url: CA.string
    , body: Compat.maybe CA.string
    , published_at: CA.string
    , draft: CA.boolean
    }

type GhArgs r =
  { owner :: String
  , repo :: String
  , token :: Maybe String
  | r
  }

generateChangelogContent :: forall r. GhArgs r -> Aff String
generateChangelogContent gh = do
  releases <- recursivelyFetchReleases [] 1 gh
  let
    realReleases = filter (\r -> r.draft == false) releases
    appendContent = foldl addReleaseInfo "" realReleases
  pure $ joinWith "\n"
    [ ""
    , appendContent
    ]
  where
    addReleaseInfo :: String -> ReleaseInfo -> String
    addReleaseInfo acc rec =
      let
        dateWithoutTimeZone = takeWhile (_ /= 'T') rec.published_at
        bodyWithFixedHeaders = fixHeaders $ trim $ fromMaybe "" rec.body
      in acc <> joinWith "\n"
        [ "## [" <> rec.tag_name <> "](" <> rec.html_url <> ") - " <> dateWithoutTimeZone
        , ""
        , bodyWithFixedHeaders
        , ""
        , ""
        ]

    fixHeaders :: String -> String
    fixHeaders s =
      let
        replaceAllHeaders =
          replaceHeaderWithBoldedText 5
            >>> replaceHeaderWithBoldedText 4
            >>> replaceHeaderWithBoldedText 3
            >>> replaceHeaderWithBoldedText 2
            >>> replaceHeaderWithBoldedText 1
      in
        joinWith "\n" $ map replaceAllHeaders (lines s)

    replaceHeaderWithBoldedText :: Int -> String -> String
    replaceHeaderWithBoldedText level line =
      let
        prefix = (power "#" level) <> " "
      in case indexOf (Pattern prefix) line of
        Nothing -> line
        Just _ -> "**" <> drop (length prefix) line <> "**"

recursivelyFetchReleases :: forall r. Array ReleaseInfo -> Int -> GhArgs r -> Aff (Array ReleaseInfo)
recursivelyFetchReleases accumulator page gh = do
  log $ "Fetching page #" <> show page
  pageNResult <- fetchNextPageOfReleases page gh
  case pageNResult of
    Nothing -> do
      log $ "Page " <> show page <> " did not have any more releases"
      pure accumulator
    Just arr -> recursivelyFetchReleases (accumulator <> arr) (page + 1) gh

fetchNextPageOfReleases :: forall r. Int -> GhArgs r -> Aff (Maybe (Array ReleaseInfo))
fetchNextPageOfReleases page gh = do
  let
    url = "https://api.github.com/repos/" <> gh.owner <> "/" <> gh.repo <> "/releases?per_page=100&page=" <> show page
    reqInfo = AX.defaultRequest
      { url = url
      , responseFormat = RF.json
      -- note to self: not sure if this authorization part is stil correct
      , headers = maybe mempty
        (\t -> [ AXRH.RequestHeader "Authorization" $ "token" <> t ]) gh.token
      }

  result <- AX.request reqInfo
  case result of
    Right rec
      | rec.status == AXSC.StatusCode 200 ->
          case decode (array releaseCodec) rec.body of
            Left e -> do
              throwError $ error $ printJsonDecodeError e
            Right releases -> do
              log $ show rec.status <> ": " <> show rec.statusText
              if null releases then do
                log "no releases found"
                pure Nothing
              else do
                log "found releases"
                pure $ Just releases
      | otherwise -> do
          let errorMessage = show rec.status <> ": " <> show rec.statusText
          throwError $ error errorMessage
    Left err -> do
      throwError $ error $ AX.printError err
