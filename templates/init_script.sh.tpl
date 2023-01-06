mkdir ~/chainlink
echo $CONFIG | base64 -d > ~/chainlink/config.toml
echo $SECRETS | base64 -d > ~/chainlink/secrets.toml
echo $TLS_CERT | base64 -d > /home/chainlink/chainlink/server.crt || true
echo $TLS_KEY | base64 -d > /home/chainlink/chainlink/server.key || true
chainlink --config ~/chainlink/config.toml --secrets ~/chainlink/secrets.toml local node