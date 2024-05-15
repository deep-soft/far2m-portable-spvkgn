[![build](https://github.com/spvkgn/far2m-portable/actions/workflows/build.yml/badge.svg)](https://github.com/spvkgn/far2m-portable/actions/workflows/build.yml)
# FAR2M File Manager — portable build
### Self-extractable standalone bundle
* includes Lua plugins and macros from [luafar2m](https://github.com/shmuz/luafar2m) repo
#### Download and run
```sh
wget -qO- https://github.com/spvkgn/far2m-portable/releases/download/latest/far2m-x86_64.run.tar | tar -xv -C /tmp && /tmp/far2m*.run
```
If needed, you can disable macros with `--nomacros`:
```sh
./far2m*.run -- --nomacros
```
