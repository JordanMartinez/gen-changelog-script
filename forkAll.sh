#!/usr/bin/env bash

filename='purescript.txt'
echo Start
while read -r -u9 p; do
  pushd ../fourteen
  gh repo fork purescript/purescript-$p --clone=true --remote=true
  popd
done 9< $filename
