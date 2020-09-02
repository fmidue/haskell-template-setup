# haskell-template-setup

## configuration

before you perform a build of an independent package db you may customise the
`env` file.

You may set the following variables for building:

| Variable          | Description |
| :---------------- | :---------- |
| `IMAGE_TAG`       | the stack-build image tag to use as basis (defaults to the resolver within `stack.yaml`) |
| `INSTALL_NEW_GHC` | When this variable is set, (if available) a newer minor version of GHC will be installed before building the package db. |
| `PKG_DB`          | the folder where the package db files will be placed. *defaults* to `$ROOT/pkgdb` |
| `ROOT`            | the folder where all files will be moved into sub-folders to - it will contain all the dynamic library and library files |

and for publishing:

| Variable          | Description |
| :---------------- | :---------- |
| `USER`            | the user which will be owner of the package db on the target |
| `GROUP`           | the group which will be group-owner of the package db on the target |
| `SSH_USER`        | the user which will be used to transfer the files to the target |
| `SERVER`          | the machine to transfer the files to (its IP or DNS name) |
| `FOLDER`          | the base folder to place files to, an timestamp will be appended to this path and result in the `TARGET` |
| `TARGET`          | the target folder if no timestamp should be used |

Of course the `stack.yaml` and `package.yaml` files may be changed as required as well.

## build

* after configuring you simply build by calling

```bash
./create.sh
```

## publish

* if you want to put all files in place you can use the provided script
  (you may use it to upload the files to a remote or your local machine).

```bash
./publish.sh
```
