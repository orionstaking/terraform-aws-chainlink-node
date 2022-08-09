mkdir ~/chainlink
echo $KEYSTORE_PASSWORD | base64 -d > ~/chainlink/.password
echo $API_CREDENTIALS | base64 -d > ~/chainlink/.api
export AZ='\"'$(curl -s $ECS_CONTAINER_METADATA_URI_V4/task | python3 -c \"import sys, json; print(json.load(sys.stdin)['AvailabilityZone'])\")'\"'
export P2P_ANNOUNCE_IP=$(echo $SUBNET_MAP | base64 -d | python3 -c \"import sys, json; print(json.load(sys.stdin)[$AZ]['ip'])\")
export DATABASE_URL=$(echo $DATABASE_URL | base64 -d)
echo [INFO] AvailabilityZone $AZ
echo [INFO] P2P_ANNOUNCE_IP $P2P_ANNOUNCE_IP
echo [INFO] P2P_ANNOUNCE_PORT $P2P_ANNOUNCE_PORT
chainlink local node -p ~/chainlink/.password -a ~/chainlink/.api