#!/bin/bash

ORGANISATION=$1
TOKEN=$2
WORK_DIR="$3/${ORGANISATION}"
PROJECT_LIMIT=$4

if [ -z "$4" ]; then
	PROJECT_LIMIT=200
fi

# Pull list of repositories from GitHub API
CURL_OUTPUT=$(curl --silent --show-error --fail -i https://api.github.com/orgs/$ORGANISATION/repos?access_token=$TOKEN'&per_page='$PROJECT_LIMIT)
if [ "$?" != 0 ]
then
	echo "Error fetching repo list from GitHub API $CURL_OUTPUT">&2
	exit 1
fi
REPO_LIST=$(echo "$CURL_OUTPUT" | grep clone_url)

# Create workdir if it doesnt exist
if [ ! -d $WORK_DIR ]; then
	mkdir -p $WORK_DIR
fi

# Change into working directory
if [ ! -z $WORK_DIR ]; then
	cd $WORK_DIR
fi

echo "$CURL_OUTPUT"|
	awk "-vtoken=$TOKEN" '
/^ *"clone_url": ".*",$/{
	gsub(/^ *"clone_url": "/, "");
	gsub(/",$/, "");
	repo=clone_url=$0
	gsub(/^.*[/]/, "", repo);
	gsub(/.git$/, "", repo);
	gsub(/^https:[/][/]/, "https://" token "@", clone_url);
	printf("%s\t%s\t%s\n", $0, repo, clone_url)
}'|
	while IFS=$'\t' read -r REPO PROJECT CLONE_URL; do
		echo Processing $REPO
		# Clone if the project doesn't exist locally
		if [ ! -d $PROJECT ]; then
		# Pull / update if the project does exist locally
			echo "Cloning $PROJECT"
			git clone $CLONE_URL || echo "Errors encountered while cloning $PROJECT">&2
		elif [ -d $PROJECT ]; then
			echo "Updating $PROJECT"
			(
				cd $PROJECT
				git pull || echo "Errors encountered while pulling $PROJECT">&2
			)
		fi
	done
