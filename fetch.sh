#!/usr/bin/env bash

OBJECT=""

count=$(jq '. | length' ./sources.json)

for ((i=0; i<$count; i++)); do

  SLUG=$( jq -r '.['$i'].slug' sources.json)

  PNAME=$(
    TEMP=$(jq -r '.['$i'].pname' sources.json)
  if [ "$TEMP" != "null" ]; then 
    echo "$TEMP"
  else 
    echo "$SLUG"
  fi
  )

  LICENSE=$(jq -r '.['$i'].license' sources.json)

  STUFF='
{
  "'$PNAME'": {
    slug: .slug,
    version: .current_version.version,
    extid: .guid,
    hash: .current_version.file.hash,
    url: .current_version.file.url,
    meta: {
      description: (.summary."en-US" // ""),
      homepage: (.homepage.url."en-US" // ""),
      mozPermissions: (.current_version.file.permissions // []),
      license: ( '$LICENSE' // .current_version.license.id )
    },
  } 
}
'

  ADD=$(curl -sX GET "https://addons.mozilla.org/api/v5/addons/addon/$SLUG/?app=firefox&lang=en-US" | jq "$STUFF")
  if [ -z "$ADD" ]; then 
  echo "$SLUG failed?"
  exit 1
  fi
  echo "$ADD"
  OBJECT="$OBJECT $ADD"
done

echo "$OBJECT" | jq -s add > generated.json
