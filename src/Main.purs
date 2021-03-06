module Main where

import Prelude

import Effect (Effect)
import Data.Foldable (fold)
import Options.Applicative as OA
import Data.String.Common (joinWith)
import Data.Maybe (Maybe(..))
import Effect.Aff (launchAff_)
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Changelog (generateChangelogContent)

main :: Effect Unit
main = do
  args <- OA.execParser $ OA.info (OA.helper <*> parser) $ fold []
  launchAff_ do
    mainContent <- generateChangelogContent args
    FS.writeTextFile UTF8 args.outputFile (initialChangelogFileText <> mainContent)

parser :: OA.Parser { owner :: String, repo :: String, outputFile :: String, token :: Maybe String }
parser = ado
  t <- OA.strOption $ fold
    [ OA.long "token"
    , OA.short 't'
    , OA.metavar "GITHUB_TOKEN"
    , OA.help "The GitHub Auth token that prevents this program from being rate-limited"
    , OA.value ""
    ]
  owner <- OA.strOption $ fold
    [ OA.long "user"
    , OA.short 'u'
    , OA.metavar "USER"
    , OA.help "The name of the user/organization who owns the repo on GitHub."
    ]

  repo <- OA.strOption $ fold
    [ OA.long "repo"
    , OA.short 'r'
    , OA.metavar "REPO"
    , OA.help "The name of the repository on GitHub. EX: `purescript-prelude`"
    ]

  outputFile <- OA.strOption $ fold
    [ OA.long "output-file"
    , OA.short 'o'
    , OA.metavar "FILE"
    , OA.help "The file that will contain the generated changelog file"
    ]
  in { owner, repo, outputFile, token: if t == "" then Nothing else Just t }

initialChangelogFileText :: String
initialChangelogFileText = joinWith "\n"
  [ "# Changelog"
  , ""
  , "Notable changes to this project are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
  , ""
  , "## [Unreleased]"
  , ""
  , "Breaking changes:"
  , ""
  , "New features:"
  , ""
  , "Bugfixes:"
  , ""
  , "Other improvements:"
  , ""
  ]
