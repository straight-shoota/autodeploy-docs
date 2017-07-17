# autodeploy-docs
Automatically deploy documentation for your code repositories.

This script does the following:
* clone the docs repository (`DOCS_REPO`, `DOCS_BRANCH`) into a working dir (`WORKDIR`)
* collect documentation from a source directory (`GENERATE_DOCS_DIR`) into a target path in the repository (`TARGET_PATH`)
* commit updates to repository (`GIT_COMMIT_MESSAGE`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`)
* push local repository to origin

It can be invoked as an after_success hook on a CI setup or run manually.
Most configuration values will work with their default values on Travis-CI or when run from a local copy of
a repository at Github. They can also be customized trough environment variables.

# Installation

```
wget https://raw.githubusercontent.com/straight-shoota/autodeploy-docs/master/autodeploy-docs.sh
```

## Usage

```bash
create_documentation && ./autodeploy-docs.sh
```

# Configuration

* **`GENERATED_DOCS_DIR`:** `$(pwd)/doc`
* **`BRANCH`:** `$TRAVIS_BRANCH` or `$(git rev-parse --abbrev-ref HEAD)`
* **`TAG`:** `$TRAVIS_TAG` or `$(git name-rev --tags --name-only "${BRANCH}")` or `latest`
* **`REPO`:** `$TRAVIS_REPO_SLUG` or `$(git ls-remote --get-url origin)`
* **`WORKDIR`:** `${HOME}/${REPO}-docs-${TAG}`
* **`DOCS_REPO`:** `https://${GH_TOKEN}@github.com/${REPO}` or `git@github.com:${REPO}`
* **`DOCS_BRANCH`:** `gh-pages`
* **`TARGET_PATH`:** `api/${TAG}`

## Contributing

1. Fork it ( https://github.com/straight-shoota/autodeploy-docs/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [straight-shoota](https://github.com/straight-shoota) Johannes Müller - creator, maintainer
