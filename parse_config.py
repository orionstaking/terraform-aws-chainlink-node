import sys
import json
import toml
import collections
import base64


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


def verify_announce_ip(announce_ip, tf_announce_ips):
    if announce_ip not in tf_announce_ips:
        sys.exit("Announce IP from config.toml isn't specified in the subnet_mapping terraform variable")

    return announce_ip


def verify_listen_addresses(listen_addresses):
    if len(listen_addresses) > 1:
        sys.exit("Please set only one listen address in ListenAddresses in your config.toml. It's required by ECS port mappings")
    elif listen_addresses[0].split(':')[0] != "0.0.0.0":
        sys.exit("Please set listen ip in ListenAddresses to 0.0.0.0 in your config.toml. It's required by ECS port mappings")

    return listen_addresses


def verify_listen_ip(listen_ip):
    if listen_ip != "0.0.0.0":
        sys.exit("Please set listen ip in ListenIP to 0.0.0.0 in your config.toml. It's required by ECS port mappings")

    return listen_ip


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

    if 'TLS' in config['WebServer'] and route53_enabled != "true" and config['WebServer']['TLS']['HTTPSPort'] != 0 :
        tls_import = "true"
        try:
            https_port = config['WebServer']['TLS']['HTTPSPort']
            cert_path = config['WebServer']['TLS']['CertPath']
            if cert_path != "/home/chainlink/chainlink/server.crt":
                sys.exit("Please set WebServer.TLS.CertPath to /home/chainlink/chainlink/server.crt in your config.toml")
            key_path = config['WebServer']['TLS']['KeyPath']
            if key_path != "/home/chainlink/chainlink/server.key":
                sys.exit("Please set WebServer.TLS.KeyPath to /home/chainlink/chainlink/server.key in your config.toml")
            secure_cookies = config['WebServer']['SecureCookies']
            if secure_cookies != True:
                sys.exit("Please set WebServer.SecureCookies to true in your config.toml. It's required by TLS configuration")
        except KeyError:
            key_err_msg("WebServer.TLS.HTTPSPort, WebServer.TLS.CertPath, WebServer.TLS.KeyPath, WebServer.SecureCookies")
    else:
        tls_import = "false"
        https_port = None
        cert_path = None
        key_path = None
        secure_cookies = "false"

    try:
        p2p_v2 = config['P2P']['V2']['Enabled']
    except KeyError:
        p2p_v2 = False

    if p2p_v2:
        p2p_networking = "V2"
        try:
            announce_addresses = verify_announce_addresses(config['P2P']['V2']['AnnounceAddresses'], tf_announce_ips)
            listen_addresses = verify_listen_addresses(config['P2P']['V2']['ListenAddresses'])
        except KeyError:
            key_err_msg("P2P.V2.AnnounceAddresses, P2P.V2.ListenAddresses")
    else:
        sys.exit("P2P V2 Networking should be enabled in config.toml")

    output = {
        "http_port": str(http_port),
        "tls_import": tls_import,
        "https_port": str(https_port),
        "cert_path": cert_path,
        "key_path": key_path,
        "secure_cookies": str(secure_cookies),
        "networking_stack": p2p_networking,
        "announce_addresses": ','.join(announce_addresses),
        "listen_addresses": ','.join(listen_addresses)
    }

    return output


if __name__ == "__main__":
    # parse input from terraform
    input_json = json.loads(sys.stdin.read())
    tf_announce_ips = input_json.get("tf_announce_ips").split(",")
    route53_enabled = input_json.get("route53_enabled")
    config_base64_string = input_json.get("config_toml")
    config_base64_bytes = config_base64_string.encode("ascii")
    config_bytes = base64.b64decode(config_base64_bytes)
    config = config_bytes.decode('ascii')

    # parse chainlink node toml config and send back to terraform  
    data = toml.loads(config)
    output = parse_config(data)
    output_json = json.dumps(output, indent=2)
    print(output_json)
