set -e

docker build -t andrew-hollis .

docker run -it -p 4129:4129 -p 35729:35729 -v ./:/usr/src/app andrew-hollis