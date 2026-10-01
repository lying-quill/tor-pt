#!/bin/bash

set -Eeuo pipefail

: "${SOURCE_JSON:?SOURCE_JSON must be set}"
: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"
: "${RUNNER_TEMP:?RUNNER_TEMP must be set}"

# TODO: for future releases
target="linux-amd64"

source_name="$(jq -r '.name' <<< "$SOURCE_JSON")"
source_url="$(jq -r '.src' <<< "$SOURCE_JSON")"
source_tag="$(jq -r '.tag' <<< "$SOURCE_JSON")"

build_root="$GITHUB_WORKSPACE/.build"
output_root="$GITHUB_WORKSPACE/.outputs"
release_root="$GITHUB_WORKSPACE/.release"

# source_dir="$build_root/$source_name"
# source_output_dir="$output_root/$source_name"

# since the jobs are running in a matrix, no need for namespacing the out dir
source_dir="$build_root"
source_output_dir="$output_root"

script_file="$RUNNER_TEMP/build-$source_name.sh"

rm -rf "$source_dir" "$source_output_dir"
mkdir -p "$build_root" "$source_output_dir" "$release_root"

echo "Cloning $source_name from $source_url at tag $source_tag"

mkdir -p "$source_dir"

git -C "$source_dir" init
git -C "$source_dir" remote add origin "$source_url"

# Fetch only the requested tag and its commit. This works for annotated
# and lightweight tags.
git -C "$source_dir" fetch \
    --depth=1 \
    origin \
    "refs/tags/$source_tag"

# Resolve the tag to its commit. For an annotated tag, ^{} peels the tag
# object and gives the commit it points to.
commit="$(git -C "$source_dir" rev-parse "FETCH_HEAD^{commit}")"

git -C "$source_dir" checkout --detach "$commit"

echo "Preparing build script"

jq -r '.build.script[]' <<< "$SOURCE_JSON" > "$script_file"
chmod +x "$script_file"

echo "Building $source_name"

cd "$source_dir"

# Run the complete script in one shell so directory changes persist.
# For example, "cd meek-client" affects the following "make" command.
bash "$script_file"

echo "Copying declared outputs"

while IFS= read -r output_item; do
    # Outputs are relative to the cloned repository root.
    relative_path="${output_item#./}"

    # Prevent an output path from escaping the cloned repository.
    case "$relative_path" in
        "" | /* | .. | ../* | */../*)
            echo "error: Invalid output path: $output_item"
            exit 1
            ;;
    esac

    source_path="$source_dir/$relative_path"
    destination_path="$source_output_dir/$relative_path"

    if [[ ! -e "$source_path" ]]; then
        echo "error: Expected output does not exist: $output_item"
        exit 2
    fi

    mkdir -p "$(dirname "$destination_path")"
    cp -a "$source_path" "$destination_path"

    echo "Copied $source_path to $destination_path"
done < <(jq -r '.build.outputs[]' <<< "$SOURCE_JSON")

# Extract the first semantic version from the source tag.
#
# Examples:
#   v2.14.1       -> 2.14.1
#   lyrebird-0.8.1 -> 0.8.1
#   v0.38.0       -> 0.38.0
version="$(
    grep -oE '[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?' <<< "$source_tag" |
        head -n 1 || true
)"

if [[ -z "$version" ]]; then
    echo "error: could not find a version string in source tag: $source_tag"
    exit 3
fi

tarball="$release_root/$source_name-$version-$target.tar.gz"

echo "Creating $tarball"

tar \
    --create \
    --gzip \
    --file "$tarball" \
    --directory "$source_output_dir" \
    .

echo "Created release tarball:"
echo "  $tarball"
