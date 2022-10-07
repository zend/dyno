#!/bin/sh

_fetch() {
  URL=$1
  M=$2
  D=$3
  H1="$4"
  H2="$5"
  H3="$6"
  H4="$7"
  H5="$8"
  OPTS=""
  if [ -x "$(which wget)" -a -z "$USE_CURL" ]; then
    CMD="wget --debug -q -O-"
    [ -n "$M" ] && CMD="$CMD --method=\"$M\""
    [ -n "$D" ] && CMD="$CMD --body-data='$D'"
    [ -n "$H1" ] && CMD="$CMD --header=\"$H1\""
    [ -n "$H2" ] && CMD="$CMD --header=\"$H2\""
    [ -n "$H3" ] && CMD="$CMD --header=\"$H3\""
    [ -n "$H4" ] && CMD="$CMD --header=\"$H4\""
    [ -n "$H5" ] && CMD="$CMD --header=\"$H5\""
    [ -n "$URL" ] && CMD="$CMD \"$URL\""
    echo $CMD
    eval $CMD
  elif [ -x "$(which curl)" ]; then
    CMD="curl -sfL"
    [ -n "$M" ] && CMD="$CMD -X $M"
    [ -n "$D" ] && CMD="$CMD -d '$D'"
    [ -n "$H1" ] && CMD="$CMD  -H \"$H1\""
    [ -n "$H2" ] && CMD="$CMD  -H \"$H2\""
    [ -n "$H3" ] && CMD="$CMD  -H \"$H3\""
    [ -n "$H4" ] && CMD="$CMD  -H \"$H4\""
    [ -n "$H5" ] && CMD="$CMD  -H \"$H5\""
    [ -n "$URL" ] && CMD="$CMD \"$URL\""
    echo $CMD
    eval $CMD
  else
    echo "Please install wget or curl, or set the PATH variables." >&2
  fi
}

_cf_api() {
  endpoint='https://api.cloudflare.com/client/v4/'
  api=$1
  method=$2
  data=$3
  _fetch "$endpoint$api" "$method" "$data" "Authorization: Bearer $CF_Token" "Content-Type: application/json" 
  echo $?
}

# Candidates: 
# ns1.dnspod.net:6666
# ipv4.icanhazip.com
# 4.ipw.cn
# ip.sb
# ident.me
# inet-ip.info
# httpbin.org/ip
# api.ipify.org
# myip.ipip.net
# Example usage: _getip ip.sb
_getip() {
  chosen=$1
  url=${chosen:-"ip.sb"}
  _fetch $url | grep -E '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' -o | head -n 1
}

# _getip ip.eaxi.com

_cf_update() {
  api="zones/$CF_Zone_ID/dns_records?type=A&match=all&name=$DOMAIN&proxied=false"
  record_id=$(_cf_api $api | grep -E '"id":"[^"]+' -o | cut -c7-)
  echo $record_id
  if [ -z $record_id ]; then
    # Record not found, create new record
    api="zones/$CF_Zone_ID/dns_records"
    _cf_api $api "POST" "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$MYIP\",\"ttl\":3600}"
  else
    update="zones/$CF_Zone_ID/dns_records/$record_id"
    _cf_api $update "PUT" "{\"type\":\"A\",\"name\":\"$DOMAIN\",\"content\":\"$MYIP\",\"ttl\":3600}"
  fi
  # _cf_api $update PUT "data"
}


# CF_Token="xxx"
# CF_Zone_ID="yyy"
# DOMAIN="zzz"

MYIP=$(_getip) _cf_update