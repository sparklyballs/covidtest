if [[ -n "${TZ}" ]]; then
  echo "Setting timezone to ${TZ}"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

cd /covid-blockchain

. ./activate

covid init

if [[ ${keys} == "generate" ]]; then
  echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
  covid keys generate
elif [[ ${keys} == "copy" ]]; then
  if [[ -z ${ca} ]]; then
    echo "A path to a copy of the farmer peer's ssl/ca required."
	exit
  else
  covid init -c ${ca}
  fi
else
  covid keys add -f ${keys}
fi

for p in ${plots_dir//:/ }; do
    mkdir -p ${p}
    if [[ ! "$(ls -A $p)" ]]; then
        echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
    fi
    covid plots add -d ${p}
done

sed -i 's/localhost/127.0.0.1/g' ~/.covid/mainnet/config/config.yaml

if [[ ${farmer} == 'true' ]]; then
  covid start farmer-only
elif [[ ${harvester} == 'true' ]]; then
  if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
    echo "A farmer peer address, port, and ca path are required."
    exit
  else
    covid configure --set-farmer-peer ${farmer_address}:${farmer_port}
    covid start harvester
  fi
else
  covid start farmer
fi

if [[ ${testnet} == "true" ]]; then
  if [[ -z $full_node_port || $full_node_port == "null" ]]; then
    covid configure --set-fullnode-port 58444
  else
    covid configure --set-fullnode-port ${var.full_node_port}
  fi
fi

while true; do sleep 30; done;
