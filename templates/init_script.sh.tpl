mkdir ~/chainlink
printf '%s' "$CONFIG" > ~/chainlink/config.toml
printf '%s' "$SECRETS" > ~/chainlink/secrets.toml
chainlink --config ~/chainlink/config.toml --secrets ~/chainlink/secrets.toml local node
