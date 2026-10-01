# tor-pt
This is a semi-automated repo that takes certain tor pluggable transports,
builds them and publishes them as a github release.

sources are specified in [json file](./sources.json) along with their repository
url and the tagged version.

the workflow also produces a pacman `PKGBUILD` file assists in installing it as
a package:

```sh
tmpdir="$(mktemp -d)"
cd "$tmpdir"
curl -fLO https://github.com/lying-quill/tor-pt/releases/latest/download/PKGBUILD
makepkg -si
```

## Development
Required tools:
- [shellcheck](https://github.com/koalaman/shellcheck) (>=0.10.0)
- [shfmt](https://github.com/mvdan/sh) (>=3.13.1)

run this command to register the git hook and run a version check for the
aforementioned tools:
```sh
make dev
```

## License
Currently licensed under the [MIT license](https://mit-license.org/).
There's a copy of the [license](LICENSE) available along with the source code.
