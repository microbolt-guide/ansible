#!/bin/sh -e

all="\
avahi-daemon,\
qemu-guest-agent,\
i2pd,\
tor,\
{{ firewall_role }},\
{{ reverse_proxy_role }},\
bitcoind,\
electrum,\
btc-rpc-explorer,\
mempool,\
public-pool,\
{{ lightning_role }},\
thunderhub, \
nostr-rs-relay,\
umbrel-nostr-relay,\
"

usage() {
    cat <<EOF
Usage: ${0##*/} [actions] [enable|disable] -s|--service [services]

Options:
  -s, --service                 Comma-separated list of services to manage
  -h, --help                    Display this help message

Actions:
  start                         Start services
  stop                          Stop services
  reload                        Reload services
  restart                       Restart services

Services:
  all                           Manage all services (default)
  avahi-daemon, avahi           Manage the avahi-daemon service
  qemu-guest-agent              Manage the qemu-guest-agent service
    qemu, qm, qmga
  i2p, i2pd                     Manage the i2pd service
  tor                           Manage the tor service
  firewall, awall, ufw          Manage the firewall service (awall, ufw)
  reverse-proxy                 Manage the reverse proxy service (caddy, nginx)
    caddy, nginx
  bitcoin                       Manage the bitcoind service
    bitcoind, knots, core
  electrum                      Manage the electrum service
    fulcrum, electrs
  btc-rpc-explorer              Manage the btc-rpc-explorer service
    btc-rpc-expl, btc-rpc,
    btcrpcexplorer, btcrpcexpl,
    btcexplorer, btcexpl
  mempool                       Manage the mempool service
    mempool.space
  public-pool                   Manage the public-pool service
    publicpool, pool
  lightning, lnd                Manage the lightning service
  thunderhub                    Manage the thunderhub service
  nostr-relay                   Manage the nostr-rs-relay service
    nostr-rs-relay
    nostr-relay-only
  nostr                         Manage the umbrel-nostr-relay service
    nostr-webapp, nostr-webgui,
    nostr-webui, nostr-umbrel,
    umbrel-nostr

Examples:
  ${0##*/} start enable
  ${0##*/} start --service bitcoin,fulcrum,nginx
  ${0##*/} stop  --service all
EOF
}

[ "$#" -eq 0 ] && {
    usage; exit 0
}

while [ "$1" ]; do case "$1" in
    start|reload|restart)
        action="${1}ed"; shift 1
    ;;
    stop)
        action="${1}ped"; shift 1
    ;;
    enable)
        enable=true; shift 1
    ;;
    disable)
        enable=false; shift 1
    ;;
    -s|--service)
        in_services="$2"; shift 2
    ;;
    -h|--help)
        usage; exit 0
    ;;
    *)
        printf "invalid option: %s\n\n" "$1"
        usage; exit 1
    ;;
esac; done

[ -z "$action" ] && [ -z "$enable" ] && {
    printf "missing action: start, stop, reload, restart, enable, disable\n\n"
    usage; exit 1
}

IFS=,; for service in $in_services; do
    case "$service" in
        all|""|" ")
            services="$all"; break
        ;;
        avahi-daemon|avahi)
            services="${services}avahi-daemon,"
        ;;
        qemu-guest-agent|qemu|qm|qmga)
            services="${services}qemu-guest-agent,"
        ;;
        i2p|i2pd)
            services="${services}i2pd,"
        ;;
        tor)
            services="${services}$service,"
        ;;
        firewall|awall|ufw)
            services="${services}{{ firewall_role }},"
        ;;
        reverse-proxy|caddy|nginx)
            services="${services}{{ reverse_proxy_role }},"
        ;;
        bitcoin|bitcoind|knots|core)
            services="${services}bitcoind,"
        ;;
        electrum|fulcrum|electrs)
            services="${services}electrum,"
        ;;
        btc-rpc-explorer|btc-rpc-expl|btc-rpc|btcrpcexplorer|btcrpcexpl|btcexplorer|btcexpl)
            services="${services}btc-rpc-explorer,"
        ;;
        mempool|mempool.space)
            services="${services}mempool,"
        ;;
        public-pool|publicpool|pool)
            services="${services}public-pool,"
        ;;
        lightning|lnd)
            services="${services}{{ lightning_role }},"
        ;;
        thunderhub)
            services="${services}thunderhub,"
        ;;
        nostr-relay|nostr-rs-relay|nostr-relay-only)
            services="${services}nostr-rs-relay,"
        ;;
        nostr|nostr-webapp|nostr-webgui|nostr-webui|nostr-umbrel|umbrel-nostr)
            services="${services}umbrel-nostr-relay,"
        ;;
        *)
            printf "invalid service: %s\n\n" "$service"
            usage; exit 1
        ;;
    esac
done
services="${services%,}"

ANSIBLE_CONFIG=./ansible.cfg \
ansible-playbook manager.yaml \
    --extra-vars "\
        service_state=${action:-} \
        service_enabled=${enable:-} \
        service_list=${services:-} \
    " \
    "$@"