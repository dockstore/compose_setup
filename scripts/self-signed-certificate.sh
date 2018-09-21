set -e
set -x

mkdir -p self-signed
openssl req -newkey rsa:2048 -nodes -keyout self-signed/key.pem -x509 -days 365 -out self-signed/certificate.pem
