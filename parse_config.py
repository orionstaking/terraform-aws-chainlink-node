import sys
import json
import toml
import collections
import subprocess


def key_err_msg(key_name):
    sys.exit(f"Required variable(s) {key_name} isn't specified in your config.toml file.")


def verify_announce_addresses(announce_addresses, tf_announce_ips):
    specified_port_list = []
    for announce_address in announce_addresses:
        specified_port_list.append(announce_address.split(':')[1])
    
    if len(set(specified_port_list)) > 1:
        sys.exit("Please set the same port for all specified IP's in AnnounceAddresses in your config.toml. It's required by AWS LB target groups")

    toml_announce_ips = []
    for announce_address in announce_addresses:
        toml_announce_ips.append(announce_address.split(':')[0])

    if collections.Counter(toml_announce_ips) != collections.Counter(tf_announce_ips):
        sys.exit("Announce IP's from config.toml and IP's provided by subnet_mapping terraform variable are not the same")

    return announce_addresses


def verify_listen_addresses(listen_addresses):
    if len(listen_addresses) > 1:
        sys.exit("Please set only one listen address in ListenAddresses in your config.toml. It's required by ECS port mappings")
    elif listen_addresses[0].split(':')[0] != "0.0.0.0":
        sys.exit("Please set listen ip in ListenAddresses to 0.0.0.0 in your config.toml. It's required by ECS port mappings")

    return listen_addresses


def parse_config(config):
    try:
        json_console = config['Log']['JSONConsole']
        if json_console != True:
            sys.exit("Please set Log.JSONConsole to true in your config.toml. It's required by CloudWatch log filters")
    except KeyError:
        key_err_msg("Log.JSONConsole")

    try:
        http_port = config['WebServer']['HTTPPort']
    except KeyError:
        key_err_msg("WebServer.HTTPPort")

    try:
        p2p_v2 = config['P2P']['V2']['Enabled']
    except KeyError:
        p2p_v2 = False

    if not p2p_v2:
        sys.exit("P2P V2 Networking should be enabled in config.toml")

    try:
        announce_addresses = verify_announce_addresses(config['P2P']['V2']['AnnounceAddresses'], tf_announce_ips)
        listen_addresses = verify_listen_addresses(config['P2P']['V2']['ListenAddresses'])
    except KeyError:
        key_err_msg("P2P.V2.AnnounceAddresses, P2P.V2.ListenAddresses")

    output = {
        "http_port": str(http_port),
        "announce_addresses": ','.join(announce_addresses),
        "listen_addresses": ','.join(listen_addresses)
    }

    return output


def load_config(input_json):
    secret_id = input_json.get("config_secret_id") or ""
    if not secret_id:
        sys.exit("Set config_plain_secret_arn.")

    command = [
        "aws", "secretsmanager", "get-secret-value",
        "--secret-id", secret_id,
        "--query", "SecretString",
        "--output", "text",
        "--region", input_json.get("aws_region"),
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        sys.exit(result.returncode)
    try:
        return toml.loads(result.stdout)
    except toml.TomlDecodeError:
        sys.exit("Config secret is not valid TOML.")


if __name__ == "__main__":
    # parse input from terraform
    input_json = json.loads(sys.stdin.read())
    tf_announce_ips = input_json.get("tf_announce_ips").split(",")

    # parse chainlink node toml config and send back to terraform
    output = parse_config(load_config(input_json))
    print(json.dumps(output))
