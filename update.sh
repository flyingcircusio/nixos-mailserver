#!/usr/bin/env bash

sed -i -e "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/$1/g" README.md

HASH=$(nix-prefetch-url "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/v2.3.0/nixos-mailserver-$1.tar.gz" --unpack)

sed -i -e "s/sha256 = \"[0-9a-z]\{52\}\"/sha256 = \"$HASH\"/g" README.md
