#!/usr/bin/env bash

set -e

## debug if desired
if [[ -n "${DEBUG}" ]]; then
    set -x
fi

## avoid noisy shellcheck warnings
MODE="${1}"
CHART_YAML="${2}"
CHART_PATH="$(dirname "${CHART_YAML}")"
TAG="${GITHUB_REF##*/}"
[[ -n "${TAG}" ]] || TAG="0.0.0"
GITHUB_TOKEN="${GITHUB_TOKEN:-dummy}"
GENERIC_BIN_DIR="/usr/local/bin"

## make this script a bit more re-usable
GIT_REPOSITORY="github.com/${GITHUB_REPOSITORY}"

## temp working vars
TIMESTAMP="$(date +%s )"
TMP_DIR="/tmp/${TIMESTAMP}"

## set up Git-User
git config --global user.name "Automatelife"
git config --global user.email "bot@unitedeffects.com"

## temporary clone git repository
git clone "https://${GIT_REPOSITORY}" "${TMP_DIR}"
cd "${TMP_DIR}"

## replace appVersion
sed -i "s#^appVersion:.*#appVersion: ${TAG}#g" "${CHART_YAML}"

## replace helm-chart version with current tag without 'v'-prefix
## sed -i "s#^version:.*#version: ${TAG/v/}#g" "${CHART_YAML}"

## useful for debugging purposes
git status

## Add new remote with credentials baked in url
git remote add publisher "https://automatelife:${GITHUB_TOKEN}@${GIT_REPOSITORY}"

CHANGE_COUNT=$(git status --porcelain | wc -l)

if [[ ${CHANGE_COUNT} -gt 0 ]] ; then
    ## add and commit changed file
    git add -A

    ## useful for debugging purposes
    git status

    ## stage changes
    git commit -m "Bump appVersion to '${TAG}'"

    ## rebase
    git pull --rebase publisher master
fi

exit 0
