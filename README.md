# tor-pt
This semi-automated repository builds certain Tor pluggable transports and
publishes them as a GitHub release.

Sources are specified in the [JSON file](./sources.json), along with their
repository URLs and tagged versions.

The workflow also produces a pacman `PKGBUILD` file to assist with installing
the transports as a package:
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
- [jq](https://github.com/jqlang/jq) (>=1.8.2)
- [GNU Make](https://www.gnu.org/software/make/) (>=4.4.1)

Run the following command to setup the development tools:
```sh
make dev
```

## License
This project is currently licensed under the
[MIT License](https://mit-license.org/).
A copy of the [license](LICENSE) is included with the source code.
