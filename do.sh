#!/usr/bin/env bash

filename='ps.txt'
echo Start
while read p; do
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
  node ./mk-changelog.js -u purescript -r $p -o "../fourteen/purescript-$p/CHANGELOG.md"

  echo "  Creating PR"
  pushd ../fourteen/purescript-$p
  git add ./CHANGELOG.md
  git commit -m "Generate CHANGELOG.md file using notes from previous GH releases"

  git add ./.github/
  git commit -m "Add pull request template"

  # git push -u origin addChangelog

  sed -i 's/0.14.0-rc3/0.14.0-rc5/' ./.github/workflows/ci.yml
  sed -i 's/0.14.0-rc4/0.14.0-rc5/' ./.github/workflows/ci.yml

  git add ./.github/
  git commit -m "Update CI in PS to v0.14.0-rc5"

  # gh pr create --repo purescript/purescript-$p --title "Generate changelog and add PR template" --body "Part of purescript/purescript#3984"
  popd
  echo "Finished PR for: $p"
done < $filename
