#! /usr/bin/env bash
#
# AUTODEPLOY-DOCS:
# Automatically deploy documentation for your code repositories.
#
# Source code and usage instructions can be found at:
#
#      https://github.com/straight-shoota/autodeploy-docs
#
# DESCRIPTION:
# This script performs the following steps:
# * clone the docs repository (`DOCS_REPO`, `DOCS_BRANCH`) into a working dir (`WORKDIR`)
# * collect documentation from a source directory (`GENERATE_DOCS_DIR) into a target path in the repository (`TARGET_PATH`)
# * commit updates to repository (`GIT_COMMIT_MESSAGE`, `GIT_COMMITTER_NAME`, `GIT_COMMITTER_EMAIL`)
# * push local repository to origin
#
# It can be invoked as an after_success hook on a CI setup or run manually.
# Most configuration values will work with their default values on Travis-CI or when run from a local copy of
# a repository at Github. They can also be customized trough environment variables.
#
# CONFIGURATION:
# Environment variables and their default values:
# * GENERATED_DOCS_DIR: $(pwd)/docs
# * BRANCH:             $TRAVIS_BRANCH
#                       $CIRCLE_BRANCH
#                       $(git rev-parse --abbrev-ref HEAD)
# * TAG:                $TRAVIS_TAG
#                       $CIRCLE_TAG
#                       $(git name-rev --tags --name-only "${BRANCH}")
#                       latest
# * REPO:               $TRAVIS_REPO_SLUG
#                       $CIRCLE_PROJECT_REPONAME
#                       $(git ls-remote --get-url origin)
# * WORKDIR:            ${HOME}/${REPO}-docs-${TAG}
# * DOCS_REPO:          https://${GH_TOKEN}@github.com/${REPO}
#                       git@github.com:${REPO}
# * DOCS_BRANCH:        gh-pages
# * GH_TOKEN:           -
# * TARGET_PATH:        api/${TAG}
#
#
#
# Copyright 2017 Johannes Müller <straightshoota@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit

if [ "$CI" = true ] && ([ "${BRANCH}" != "master" ] || [ "${
_PULL_REQUEST}" = "true" ]); then
  echo -e "Aborting docs generation, we're on CI and this is not a push to master"
  echo -e "TAG=${TAG}"
  echo -e "BRANCH=${BRANCH}"
  exit 0
fi

GENERATED_DOCS_DIR="${GENERATED_DOCS_DIR:-"$(pwd)/docs"}"
if [ ! -d "$GENERATED_DOCS_DIR" ]; then
  echo -e "Source directory \`$GENERATED_DOCS_DIR\` does not exist."
  echo -e "Please create the documentation at this path or change it by assigning a different path to \$GENERATER_DOCS_DIR"
  exit 1
fi

BRANCH="${BRANCH:-${TRAVIS_BRANCH:-${CIRCLE_BRANCH}}}"
TAG="${TAG:-${TRAVIS_TAG:-${CIRCLE_TAG}}}"
REPO="${REPO:-${TRAVIS_REPO_SLUG:-${CIRCLE_PROJECT_REPONAME}}}"

if [ "$BRANCH" = "" ]; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)

  if [ "$TAG" = "" ]; then
    TAG=$(git name-rev --tags --name-only "${BRANCH}")
  fi
fi

if [ "$REPO" = "" ]; then
  REPO=$(git ls-remote --get-url origin)
  REPO="${REPO#*:}"
fi

if [ "$TAG" = "undefined" ] || [ "$TAG" = "" ]; then
  TAG="latest"
fi

WORKDIR="${WORKDIR:-"$HOME/${REPO}-docs-${TAG}"}"
if [ "$DOCS_REPO" == "" ]; then
  if [ "$GH_TOKEN" = "" ]; then
    DOCS_REPO="git@github.com:${REPO}"
    DOCS_REPO_SAFE="$DOCS_REPO"
  else
    DOCS_REPO="https://${GH_TOKEN}@github.com/${REPO}"
    DOCS_REPO_SAFE="https://[secret]@github.com/${REPO}"
  fi
else
  DOCS_REPO_SAFE="$DOCS_REPO"
fi
DOCS_BRANCH="${DOCS_BRANCH:-gh-pages}"
TARGET_PATH="${TARGET_PATH:-"api/${TAG}"}"

function run_subcommand() {
  echo -e "  ==> $*"
  "$@"
  echo -e "  ==> done $1"
  echo -e ""
}

function failed_git_clone() {
  echo -e "\033[31mError: \033[0;1mCould not clone ${DOCS_REPO}"
  echo -e "Please make sure that you can successfully connect to the git repository by either setting up a SSH key (preferred) or assigning a Github API token."
  exit 1
}

echo -e "Autodeploying documentation for branch ${BRANCH} ($TAG) from ${GENERATED_DOCS_DIR}"

### Clone docs repository
echo -e "Checking out docs repository ${DOCS_REPO_SAFE} ${DOCS_BRANCH} into ${WORKDIR}"
echo -e ""

rm -rf "${WORKDIR}"
if [ "$CI" = true ]; then
  git clone --quiet --branch="${DOCS_BRANCH}" "${DOCS_REPO}" "${WORKDIR}" > /dev/null 2>/dev/null || failed_git_clone
else
  run_subcommand git clone --branch="${DOCS_BRANCH}" "${DOCS_REPO}" "${WORKDIR}"
fi

cd "${WORKDIR}"

git rm -rf "${TARGET_PATH}" --ignore-unmatch --quiet

## Collect docs from source

mkdir -p "${TARGET_PATH}"
rsync -a "${GENERATED_DOCS_DIR}/" "${TARGET_PATH}"
if [ "$BRANCH" = "master" ]; then
  run_subcommand cp -v "${GENERATED_DOCS_DIR}/README.md" "${WORKDIR}"
fi

## Commit updates to repository
git -c core.fileMode=false add -f .

if [ "$CI" = true ]; then
  BUILD_NOTICE_CI=" on successful travis build ${TRAVIS_BUILD_NUMBER:-${CIRCLE_BUILD_NUM}}"
else
  run_subcommand git -c core.fileMode=false status
fi

LOCAL_GIT_CONF=()
if [ "$GIT_COMMITTER_NAME" != "" ]; then
  LOCAL_GIT_CONF=(-c "user.name=$GIT_COMMITTER_NAME" -c "user.email=$GIT_COMMITTER_EMAIL")
fi

if [ "$GIT_COMMIT_MESSAGE" = "" ]; then
  GIT_COMMIT_MESSAGE="Docs generated${BUILD_NOTICE_CI} for ${BRANCH} ($TAG)"
fi
# TOOO: pipe git commit through `head -n 3` to show only the status information
run_subcommand git "${LOCAL_GIT_CONF[@]}" commit -m "$GIT_COMMIT_MESSAGE"

## Push local repository to origin
if [ "$CI" = true ]; then
  git push -fq origin "${DOCS_BRANCH}" > /dev/null 2>/dev/null
else
  run_subcommand git push -f origin "${DOCS_BRANCH}"
fi

echo -e "Deployed generated docs to ${DOCS_REPO_SAFE} ${DOCS_BRANCH}."
