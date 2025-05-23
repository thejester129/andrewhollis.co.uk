set -e

docker build -t andrew-hollis .
docker run -it -p 4129:4129 andrew-hollis