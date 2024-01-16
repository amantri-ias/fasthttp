#!/bin/bash

# USAGE: compute_build_version
function compute_build_version() {
	#get highest tag number
	local VERSION="$(git describe --abbrev=0 --tags)"

	# NOTE: Major includes "v" as a prefix. example, v0
	local MAJOR="$(echo "${VERSION}"  | cut -d'.' -f 1)"
	local MINOR="$(echo "${VERSION}"  | cut -d'.' -f 2)"
	local PATCH="$(echo "${VERSION}"  | cut -d'.' -f 3)"
	PATCH="$(($PATCH + 1))"

	local vfile="$(cat version)"
	if [[ "$MAJOR.$MINOR.0" == "${vfile}" ]]; then
		echo "$MAJOR.$MINOR.$PATCH"
	else
		echo "${vfile}"
	fi
}

# USAGE: commit_range
function commit_range() {
	if [[ "${CIRCLE_BRANCH}" = "master" ]]; then
		# Extract commit range (or single commit)
		COMMIT_RANGE="$(git rev-parse HEAD)"
	else
		COMMIT_RANGE="$(git merge-base origin/master HEAD)..."
	fi

	# Fix single commit, unfortunately we don't always get a commit range from Circle CI
	if [[ $COMMIT_RANGE != *"..."* ]]; then
		COMMIT_RANGE="${COMMIT_RANGE}~...${COMMIT_RANGE}"
	fi

	echo "${COMMIT_RANGE}"
}

# USAGE: changed_targets "$(commit_range)"
function changed_targets() {
	local range="${1}"
	if [[ "${range}" == "" ]]; then
		range="$(commit_range)"
	fi
	local out="$(mktemp)"
	touch "${out}"
	git --no-pager diff --name-only "${range}" >> "${out}"
	git --no-pager diff --name-only >> "${out}"
	cat "${out}"
	rm -rf "${out}" > /dev/null
}

function git_tag() {
	if [[ "${1}" == "" ]]; then
		echo "ERR: build version not found"
		exit 1
	fi
	eval $(ssh-agent)
	find "$HOME/.ssh" -name "id_rsa_*" -exec ssh-add {} \;

	export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	git config --global user.name "Publica CI" > /dev/null
	git config --global user.email "bret+infra@getpublica.com" > /dev/null
	git tag -a "${1}" -m "v${1}"
	git push origin "${1}"
}