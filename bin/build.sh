#!/bin/bash

export REPODIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")/../")"

pushd "${REPODIR}/cli" > /dev/null

mkdir -p "${REPODIR}/dist"



go build


errcode="$?"

popd > /dev/null

if [[ "${errcode}" != "0" ]]; then
	exit "${errcode}"
fi