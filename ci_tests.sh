# Use tests.sh instead, when running locally
set -e

source ci-helpers.sh

echo "Preparing Docker image ..."

sh ci-cleanup.sh
sh ci-runtime-prepare.sh
sh ci-runtime-build.sh

LATEST_VERSION=$(yq ".$RUNTIME.versions[0]" ci/runtimes.toml)
if [ "$VERSION" = "$LATEST_VERSION" ]; then
    echo "Running formatter ..."

    cd ./runtimes/$RUNTIME_FOLDER
    docker run --rm --name open-runtimes-formatter -v $(pwd):/mnt/code:rw open-runtimes/test-runtime sh -c "cd /mnt/code && $FORMATTER_PREPARE && $FORMATTER_CHECK"
    cd ../../

    if [ -d "tests/resources/functions/$RUNTIME_FOLDER" ]; then
        cd "tests/resources/functions/$RUNTIME_FOLDER"
        docker run --rm --name open-runtimes-formatter -v $(pwd):/mnt/code:rw open-runtimes/test-runtime sh -c "cd /mnt/code && $FORMATTER_PREPARE && $FORMATTER_CHECK"
        cd ../../../../
    fi
else
    echo "Skipping formatter. Formatter runs only in: $RUNTIME-$LATEST_VERSION"
fi

echo "Running tests ..."
mkdir -p ./tests/.runtime

if ! [ -z "$ENFORCED_RUNTIME" ]; then
    cp -R ./tests/resources/functions/$RUNTIME/* ./tests/.runtime
else
    cp -R ./tests/resources/functions/$RUNTIME_FOLDER/latest/* ./tests/.runtime
        if [ -d "./tests/resources/functions/$RUNTIME_FOLDER/$VERSION_FOLDER/" ]; then
        cp -R ./tests/resources/functions/$RUNTIME_FOLDER/$VERSION_FOLDER/* ./tests/.runtime
    fi
fi

# Prevent Docker from creating folder
cd ./tests/.runtime
rm -rf code.tar.gz
touch code.tar.gz

BUILD_SCRIPT="helpers/build.sh"
START_SCRIPT="helpers/start.sh"

# Build
docker run --rm --name open-runtimes-test-build -v /tmp/.build:/usr/local/server/.build -v $(pwd):/mnt/code:rw -e OPEN_RUNTIMES_OUTPUT_DIRECTORY="$OUTPUT_DIRECTORY" -e OPEN_RUNTIMES_ENTRYPOINT="$ENTRYPOINT" open-runtimes/test-runtime sh -c "$BUILD_SCRIPT \"$INSTALL_COMMAND\""

# Tools test
echo "Testing tools ..."
docker run --name open-runtimes-test-tools open-runtimes/test-runtime sh -c "$TOOLS"
OUTPUT=$(docker logs open-runtimes-test-tools)
EXIT_CODE=$(docker inspect open-runtimes-test-tools --format='{{.State.ExitCode}}')
docker rm --force open-runtimes-test-tools

if [[ "$EXIT_CODE" == "0" ]]; then
    echo "All tools installed properly"
else
    echo "Tools are not installed properly"
    exit 1
fi

# Prepare Docker network
docker network inspect openruntimes || docker network create openruntimes

# Main tests
docker run --network openruntimes -d --name open-runtimes-test-serve -v /tmp/logs:/mnt/logs -v $(pwd)/code.tar.gz:/mnt/code/code.tar.gz:rw -e OPEN_RUNTIMES_HEADERS="{\"x-custom\":\"value\",\"X-CUSTOM-UPPERCASE\":\"Value2\",\"x-open-runtimes-custom\":248}" -e OPEN_RUNTIMES_ENTRYPOINT="$ENTRYPOINT" -e OPEN_RUNTIMES_SECRET=test-secret-key -e CUSTOM_ENV_VAR=customValue -p 3000:3000 open-runtimes/test-runtime sh -c "sh $START_SCRIPT \"$START_COMMAND\""

# Development tests
docker run --network openruntimes -d --name open-runtimes-test-serve-dev -v /tmp/logs:/mnt/logs -v $(pwd)/code.tar.gz:/mnt/code/code.tar.gz:rw -e OPEN_RUNTIMES_HEADERS= -e OPEN_RUNTIMES_ENV=development -e OPEN_RUNTIMES_ENTRYPOINT="$ENTRYPOINT" -e OPEN_RUNTIMES_SECRET= -e CUSTOM_ENV_VAR=customValue -p 3001:3000 open-runtimes/test-runtime sh -c "sh $START_SCRIPT \"$START_COMMAND\""

cd ../../

docker run  -v /var/run/docker.sock:/var/run/docker.sock --network openruntimes --rm -e RUNTIME_NAME="$RUNTIME" -e RUNTIME_VERSION="$VERSION" -e OPEN_RUNTIMES_SECRET="test-secret-key" -e OPEN_RUNTIMES_ENTRYPOINT=$ENTRYPOINT -v $PWD:/app -v /tmp:/tmp -w /app phpswoole/swoole:5.1.2-php8.3-alpine sh -c "apk update && apk add docker-cli && vendor/bin/phpunit --configuration phpunit.xml tests/$TEST_CLASS"
