#!/usr/bin/env bash

filename='purescript-web.txt'
echo Start
while read -r -u9 p; do
  echo "==============="
  echo "Creating PR for $p"
  echo ""
  echo "  Creating branch"
  pushd ../fourteen/purescript-$p
  git fetch upstream
  git reset --hard HEAD
  git checkout upstream/master
  git switch -c addChangelog
  popd

  echo "  Copying PR template to folder"
  cp ./PULL_REQUEST_TEMPLATE.md ../fourteen/purescript-$p/.github/

  echo "  Generating changelog"
  node ./mk-changelog.js -u purescript-web -r $p -o "../fourteen/purescript-$p/CHANGELOG.md" -t $1

  pushd ../fourteen/purescript-$p
  git add ./CHANGELOG.md
  git commit -m "Generate CHANGELOG.md file using notes from previous GH releases"

  git add ./.github/
  git commit -m "Add pull request template"

  sed -i 's/0.14.0-rc3/0.14.0-rc5/' ./.github/workflows/ci.yml
  sed -i 's/0.14.0-rc4/0.14.0-rc5/' ./.github/workflows/ci.yml

  git add ./.github/
  git commit -m "Update CI in PS to v0.14.0-rc5"

  echo "  Creating PR"
  git push -u origin addChangelog
  gh pr create --repo purescript/purescript-$p --title "Generate changelog and add PR template" --body "Part of purescript/purescript#3986"
  popd
  echo "Finished PR for: $p"
done 9< $filename
