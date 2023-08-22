#!/bin/bash
################################
# Author: chaithra
# Version: v1
#
#Script to retrieve information from GitHub
#
# 
################################

if [ ${#@} - lt 2 ]
then
    echo "usage: $0 [github-token] [REST expression]"
    exit 1;
fi

GITHUB_TOKEN=$1
GITHUB_API_REST=$2

GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github.v3+json"

temp=`basename $0`
TEMPFILE=`mktemp /tmp/${temp}.XXXXXX` || exit 1


function restcall {
    curl -s -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token ${GITHUB_TOKEN}" >> $TEMPFILE
  }

lastpage=`curl -s -I "https://api.github.com${GITHUB_API_REST}" -H "${GITHUB_API_HEADER_ACCEPT}" -H "Authorization: token $GITHUB_TOKEN" | grep '^Link:' | sed -e 's/^Link:.*page=//g' -e 's/>.*$//g'`

cat $TEMPFILE

  
