set -xe

repo=ciscocloud
version=${TRAVIS_TAG:-edge}

docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
docker build -t $repo/mantl-elasticsearch-client:$version --rm .
docker push $repo/mantl-elasticsearch-client:$version

if [ "$version" != 'edge' ]; then
    docker tag $repo/mantl-elasticsearch-client:$version $repo/mantl-elasticsearch-client:latest
    docker push $repo/mantl-elasticsearch-client:latest
fi
