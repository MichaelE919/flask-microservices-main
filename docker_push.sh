#!/bin/sh

if [ -z "$TRAVIS_PULL_REQUEST" ] || [ "$TRAVIS_PULL_REQUEST" == "false" ]
then

  if [ "$TRAVIS_BRANCH" == "development" ]; then
    docker login -e $DOCKER_EMAIL -u $DOCKER_ID -p $DOCKER_PASSWORD
    export TAG="$TRAVIS_BRANCH"
    export REPO=$DOCKER_ID
  fi

  if [ "$TRAVIS_BRANCH" == "staging" ] || \
     [ "$TRAVIS_BRANCH" == "production" ]
  then
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    ./awscli-bundle/install -b ~/bin/aws
    export PATH=~/bin:$PATH
    # add AWS_ACCOUNT_ID, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY env vars
    eval $(aws ecr get-login --no-include-email --region us-east-1)
    export TAG=$TRAVIS_BRANCH
    export REPO=$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
  fi


  if [ "$TRAVIS_BRANCH" == "development" ] || \
     [ "$TRAVIS_BRANCH" == "staging" ] || \
     [ "$TRAVIS_BRANCH" == "production" ]
  then
    # users
    docker build -t $USERS:$COMMIT $USERS_REPO 
    docker tag $USERS:$COMMIT $DOCKER_ID/$USERS:$TAG
    docker push $DOCKER_ID/$USERS:$TAG
    # users db
    docker build -t $USERS_DB:$COMMIT $USERS_DB_REPO 
    docker tag $USERS_DB:$COMMIT $DOCKER_ID/$USERS_DB:$TAG
    docker push $DOCKER_ID/$USERS_DB:$TAG
    # client
    docker build -t $CLIENT:$COMMIT $CLIENT_REPO
    docker tag $CLIENT:$COMMIT $DOCKER_ID/$CLIENT:$TAG
    docker push $DOCKER_ID/$CLIENT:$TAG
    # swagger
    docker build -t $SWAGGER:$COMMIT $SWAGGER_REPO
    docker tag $SWAGGER:$COMMIT $DOCKER_ID/$SWAGGER:$TAG
    docker push $DOCKER_ID/$SWAGGER:$TAG
    # nginx
    docker build -t $NGINX:$COMMIT $NGINX_REPO 
    docker tag $NGINX:$COMMIT $DOCKER_ID/$NGINX:$TAG
    docker push $DOCKER_ID/$NGINX:$TAG
  fi
fi
