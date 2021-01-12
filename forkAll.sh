#!/usr/bin/env bash

filename='purescript-web.txt'
echo Start
while read -r -u9 p; do
  pushd ../fourteen
  gh repo fork purescript-web/purescript-$p --clone=true --remote=true
  popd
done 9< $filename
