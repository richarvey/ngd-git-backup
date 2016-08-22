#!/bin/bash

ORGANISATION=$1
TOKEN=$2
WORK_DIR="$3/${ORGANISATION}"

# Pull list of repositories from GitHub API
REPO_LIST=$(curl -i https://api.github.com/orgs/$ORGANISATION/repos?access_token=$TOKEN | grep clone_url)

# Create workdir if it doesnt exist
if [ ! -d $WORK_DIR ]; then
  mkdir -p $WORK_DIR
fi 

# Change into working directory
if [ ! -z $WORK_DIR ]; then
  cd $WORK_DIR
fi

for REPO in $REPO_LIST; do
  if [[ $REPO != "\"clone_url\":" ]]; then
    REPO=$(echo $REPO | tr -d "\"" | tr -d ",")
    PROJECT=$(echo $REPO | awk -F '/' '{print $5} ' | awk -F '.' '{print $1} ')
    # Clone if the project doesn't exisit locally
    if [ ! -d $PROJECT ]; then
      # cut https:// off to insert <token>@
      REPO=$(echo $REPO | awk -F 'https://' '{print $2} ' )
      echo "Cloning $PROJECT"
      CLONE_URL=$(echo "https://"$TOKEN"@"$REPO)
      git clone $CLONE_URL 
    # Pull / update if the project does exist locally
    elif [ -d $PROJECT ]; then
      cd $PROJECT
      echo "Updating $PROJECT"
      git pull
      cd $WORK_DIR
    fi	
  fi	
done
