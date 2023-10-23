#!/usr/bin/env bash

OBJECT=""

readarray -t ARRAY < <(jq -c '.[]' sources.json)

for object in "${ARRAY[@]}"; do

  SLUG=$(jq --raw-output '.slug' <<< "$object")

  PNAME=$(jq --raw-output '.pname // .slug' <<< "$object")

  LICENSE=$(jq --raw-output '.license' <<< "$object")

  ADD=$(curl --silent \
    --request GET \
    --url "https://addons.mozilla.org/api/v5/addons/addon/$SLUG/?app=firefox&lang=en-US" \
    | jq '{
    "'"$PNAME"'": {
    slug: .slug,
    version: .current_version.version,
    extid: .guid,
    hash: .current_version.file.hash,
    url: .current_version.file.url,
    meta: {
      description: (.summary."en-US" // ""),
      homepage: (.homepage.url."en-US" // ""),
      mozPermissions: (.current_version.file.permissions // []),
      license: ( '"$LICENSE"' // .current_version.license.id )
    },
  } 
}
')

if [ -z "$ADD" ]; then 
  echo "$SLUG failed?"
  exit 1
fi

echo "$ADD"

OBJECT="$OBJECT $ADD"

done

jq -s add <<< "$OBJECT" > generated.json
