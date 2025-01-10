set -e

if [ -n "$OPEN_RUNTIMES_OUTPUT_DIRECTORY" ]; then
    cd $OPEN_RUNTIMES_OUTPUT_DIRECTORY
fi

mkdir -p .build
mv ./* .build/

mv .build/ build/

if [ -d "/usr/local/build/public/" ]; then
    mv /usr/local/build/public/ ./public/
fi

mv /usr/local/build/package*.json ./
mv /usr/local/build/node_modules/ ./node_modules/
