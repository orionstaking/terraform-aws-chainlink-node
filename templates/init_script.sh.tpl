mkdir ~/chainlink
echo $CONFIG | base64 -d > ~/chainlink/config.toml
echo $SECRETS | base64 -d > ~/chainlink/secrets.toml
echo $TLS_CERT | base64 -d > $TASK_TLS_CERT_PATH || true
echo $TLS_KEY | base64 -d > $TASK_TLS_KEY_PATH || true
chainlink --config ~/chainlink/config.toml --secrets ~/chainlink/secrets.toml local node