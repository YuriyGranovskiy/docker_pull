#!/bin/bash
full_image_name=$1
image_name=$(cut -d: -f1 <<< $full_image_name)
tag_name=$(cut -d: -f2 <<< $full_image_name)

registry_host=registry-1.docker.io

manf_listv2_header="Accept: application/vnd.docker.distribution.manifest.list.v2+json"
manf_v2_header="Accept: application/vnd.docker.distribution.manifest.v2+json"

image_name_url=$(echo ${image_name//\//%2F})

echo "Getting token for $full_image_name..."
token=$(curl -s --insecure "https://auth.docker.io/token?scope=repository%3Alibrary%2F${image_name}%3Apull&service=registry.docker.io" | jq -r .token)

authz_header="Authorization: Bearer ${token}"

echo "Getting manifest for tag $tag_name..."
digest=$(curl -s --insecure \
	-H "$manf_listv2_header" \
	-H "$authz_header" \
	"https://${registry_host}/v2/library/${image_name_url}/manifests/${tag_name}" | jq -r '.manifests[] | select (.platform.architecture == "amd64" and .platform.os == "linux") | .digest')

layers=$(curl -s --insecure \
	-H "$manf_v2_header" \
	-H "$authz_header" \
	"https://${registry_host}/v2/library/${image_name}/manifests/${digest}" | jq -r .layers)
counter=0
layers_count="$(echo $layers | jq length)"

echo Found $layers_count layers
mkdir -p $image_name
while [[ $counter -lt $layers_count ]]; do
	layer_digest=$(echo $layers | jq --arg c $counter -r '.[($c | tonumber)].digest' )
	layer_path=$(echo "$layer_digest" | tr ":" "/")
	echo $layer_path
	let counter+=1
    echo "Downloading layer $layer_digest ($counter of $layers_count) ..."
	curl -Ls --insecure \
		-H "$authz_header" \
		-o "$image_name/$layer_path.tgz" \
		"https://${registry_host}/v2/library/${image_name}/blobs/${layer_digest}"
	echo Layer ${layer_digest} downloaded.
done

