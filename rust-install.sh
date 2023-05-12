#!/usr/bin/env bash

set -exou pipefail

TMPDIR=$(mktemp -d)

if [[ "$INPUT_VERSION" == "latest" ]]; then
  echo "Downloading the latest release"
  # Set the latest release version
  VERSION=$(curl --silent -H "Authorization: token $INPUT_TOKEN" "https://api.github.com/repos/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
else
  echo "Downloading version $INPUT_VERSION"
  VERSION=$INPUT_VERSION
fi

# Determine the operating system and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

if [[ $OS == "darwin" ]]; then
  FILENAME="${INPUT_REPOSITORY}_${VERSION}_x86_64-apple-darwin.zip"
  URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
  SHA256SUM_FILE="${FILENAME}.sha256sum"
elif [[ $OS == "linux" ]]; then
  if [[ $ARCH == "x86_64" ]]; then
    FILENAME="${INPUT_REPOSITORY}_${VERSION}_x86_64-unknown-linux-musl.tar.gz"
    URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
    SHA256SUM_FILE="${FILENAME}.sha256sum"
  else
    echo "Unsupported architecture: $ARCH"
    exit 1
  fi
elif [[ $OS == "windows" ]]; then
  FILENAME="${INPUT_REPOSITORY}_${VERSION}_x86_64-pc-windows-gnu.zip"
  URL="https://github.com/$INPUT_REPOSITORY_OWNER/$INPUT_REPOSITORY/releases/download/${VERSION}/${FILENAME}"
  SHA256SUM_FILE="${FILENAME}.sha256sum"
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

OUTPUT_FILE="$TMPDIR/$FILENAME"
SHA256SUM_OUTPUT_FILE="$TMPDIR/$SHA256SUM_FILE"

# Download the binary and its checksum file to the temporary directory
echo "Downloading $URL"
curl --silent -H "Authorization: token $INPUT_TOKEN" --location --output "$OUTPUT_FILE" "$URL"
echo "Downloading $SHA256SUM_URL"
curl --silent -H "Authorization: token $INPUT_TOKEN" --location --output "$SHA256SUM_OUTPUT_FILE" "$URL.sha256sum"

# Verify the checksum
shasum -a 256 -c "$SHA256SUM_OUTPUT_FILE"

# Extract the binary in the temporary directory
if [[ $OS == "darwin" ]]; then
  unzip "$OUTPUT_FILE" -d $TMPDIR
elif [[ $OS == "linux" ]]; then
  tar -xzf "$OUTPUT_FILE" -C $TMPDIR
elif [[ $OS == "windows" ]]; then
  unzip "$OUTPUT_FILE" -d $TMPDIR
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Make the binary executable
chmod +x $TMPDIR/$INPUT_REPOSITORY

# Return the binary path
echo "binary_path=$TMPDIR/$INPUT_REPOSITORY" >> $GITHUB_OUTPUT
