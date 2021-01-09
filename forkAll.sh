#!/usr/bin/env bash

filename='purescript.txt'
echo Start
while read p; do
  echo "==============="
  echo "Forking $p"
  pushd ../fourteen
  gh repo fork purescript/purescript-$p --clone=true --remote=true
  popd
  echo "Finished forking for: $p"
done < $filename
