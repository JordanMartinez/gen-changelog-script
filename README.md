# gen-changelog-script

Script written in PureScript that will help generate a `CHANGELOG.md` file for each of the core PureScript repos

## To build and run

```bash
git clone https://github.com/JordanMartinez/gen-changelog-script.git
cd gen-changelog-script
npm i
npm run build

# Creates the `./CHANGELOG.md` file and fills it with
# releates notes from `purescript/purescript-prelude` repo
node ./genChangelog.js -u purescript -r purescript-prelude -o CHANGELOG.md
```
