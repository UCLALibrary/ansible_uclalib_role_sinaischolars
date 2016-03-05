#! /bin/bash

#
# Kind of backwards, but we'll trigger Jenkins from Ansible to start a new build
# Also, when we get a production Jenkins, use a Jenkins user other than ksclarke
#

JOB_URL="https://jenkins.library.ucla.edu/job/sinai-web"
JOB_STATUS_URL="${JOB_URL}/lastBuild/api/json"

GREP_RETURN_CODE=0
LOOP_LIMIT=24
LOOP_COUNT=0

if [[ "$3" == "library.ucla.edu" ]] || [[ "$3" == "us-west-1.compute.internal" ]] || [[ "$3" == "eu-central-1.compute.internal"  ]]; then
  HOST_NAME="stage-sinai.library.ucla.edu"
  SOLR_SERVER="http%3A%2F%2Ftemp-solrsearch.library.ucla.edu%2Fsolr%2Fsinai"
  JKS_PATH="/etc/sinai/sinai.jks"
else
  HOST_NAME="localhost"
  SOLR_SERVER="http%3A%2F%2Flocalhost%3A8983%2Fsolr%2Fsinai"
  JKS_PATH="sinai.jks"
fi

# Start the build
curl -u "ksclarke:${1}" -L -s "${JOB_URL}/buildWithParameters?delay=0sec&HOST=${HOST_NAME}&JKS=${JKS_PATH}&SOLR_HOST=${SOLR_SERVER}&token=${2}"

# Poll every ten seconds until the build is finished
while [ $GREP_RETURN_CODE -eq 0 ]
do
    sleep 10
    LOOP_COUNT=$(($LOOP_COUNT+1))

    # Let's add a sanity check to avoid endless looping
    if [ "$LOOP_COUNT" -ge "$LOOP_LIMIT" ]; then
      break
    fi

    # Grep should return a 0 while the build is running
    curl -u ksclarke:${1} -s ${JOB_STATUS_URL} | grep "result\":null" > /dev/null
    GREP_RETURN_CODE=$?
done
