#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
VERSION=7.1.0
SQUIDEX_REPO_NAME="squidex"

cd $SCRIPT_DIR

if [ -d $SCRIPT_DIR"/"$SQUIDEX_REPO_NAME ] 
then
    cd squidex
    git checkout master
    git checkout HEAD -- Dockerfile
else
    git clone "https://github.com/Squidex/squidex.git"
    git checkout master
fi

cd $SCRIPT_DIR/$SQUIDEX_REPO_NAME

git fetch --all --tags

if [ $(git tag -l "$VERSION") ]; then
    echo $VERSION" does exists"
else
    echo "tag does not exist"
    exit 1
fi


# docker buildx imagetools inspect mcr.microsoft.com/dotnet/aspnet:6.0.0-bullseye-slim


# FROM mcr.microsoft.com to FROM --platform=$BUILDPLATFORM mcr.microsoft.com
sed 's/FROM mcr.microsoft/FROM --platform=\$BUILDPLATFORM mcr.microsoft/' Dockerfile > Dockerfile.tmp
mv Dockerfile.tmp Dockerfile
# end BUILDPLATFORM replace

# FROM buildkit to FROM --platform=$BUILDPLATFORM buildkit
sed 's/FROM buildkit/FROM --platform=\$BUILDPLATFORM buildkit/' Dockerfile > Dockerfile.tmp
mv Dockerfile.tmp Dockerfile
# end BUILDPLATFORM replace


# disable unit tests
sed 's/RUN dotnet test/RUN echo "disabled: " dotnet test/' Dockerfile > Dockerfile.tmp
mv Dockerfile.tmp Dockerfile
# end unit test replace

# publish add
sed 's/RUN dotnet publish/RUN dotnet publish $NET_TARGET_PLATFORM_ARG/' Dockerfile > Dockerfile.tmp
mv Dockerfile.tmp Dockerfile
# end publish replace

# restore add
sed 's/RUN dotnet restore/RUN dotnet restore $NET_TARGET_PLATFORM_ARG/' Dockerfile > Dockerfile.tmp
mv Dockerfile.tmp Dockerfile
# end restore replace


>$SCRIPT_DIR"/"$SQUIDEX_REPO_NAME"/Dockerfile.bak"
while read line
do
    echo $line >>$SCRIPT_DIR"/"$SQUIDEX_REPO_NAME"/Dockerfile.bak"
    echo $line | grep -q "platform=\$BUILDPLATFORM"
    [ $? -eq 0 ] && cat $SCRIPT_DIR"/dockerfile_runtime_arg" >> $SCRIPT_DIR"/"$SQUIDEX_REPO_NAME"/Dockerfile.bak"
done < Dockerfile
mv Dockerfile.bak Dockerfile


echo " display for debug"
cat Dockerfile

# docker buildx build --push squidex --tag qdraw/squidex:latest --platform linux/arm64