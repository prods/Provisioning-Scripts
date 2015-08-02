# Index of string
string_index() {
  x="${1%%$2*}"
  [[ $x = $1 ]] && echo -1 || echo ${#x}
}

# Get Hash
get_hash() {
  STR=$(date +"%s")
  if [[ -z "$STR" ]]; then
    STR="$1"
  fi
  echo -n "$STR" | md5sum
}

# Get IP Address
get_eth0_ip() {
  echo "$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
}
