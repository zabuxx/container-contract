# container-contract.sh

Build Ink! contracts through [paritytech/contracts-ci-linux](https://hub.docker.com/r/paritytech/contracts-ci-linux) docker container without installing Rust or dependencies.

## TL;DR

Copy *container-contract.sh* somewhere in your PATH (e.g. *$HOME/bin*) and issue a command to be executed through container:

	$ container-contract.sh rustup toolchain list
       stable-x86_64-unknown-linux-gnu (default)
       nightly-2023-03-21-x86_64-unknown-linux-gnu
       nightly-x86_64-unknown-linux-gnu
    $ cd ink-examples/flipper/
	$ container-contract.sh cargo +nightly contract build --release
       [1/*] Building cargo project
         Compiling proc-macro2 v1.0.66
         Compiling unicode-ident v1.0.11
         ...
		 
Alternatively, you can set an alias for e.g. *cargo* to compile through container transparently:

    $ alias cargo='container-contract.sh cargo'
    $ cd ink-examples/flipper/
    $ cargo +nightly contract build --release
       [1/*] Building cargo project
         Compiling proc-macro2 v1.0.66
         Compiling unicode-ident v1.0.11
	     ...
		 
## Usage

### Why

Getting your [Ink! environment setup](https://use.ink/getting-started/setup/) locally involves several steps, and keeping it up-to-date and compatible can be a tedious task in the long run.

Advantages of using [paritytech/contracts-ci-linux](https://hub.docker.com/r/paritytech/contracts-ci-linux):

* No need to set up or update Ink! environment locally, only dependency is Podman/Docker
* At all times an up-to-date working Ink! toolchain
* Reproducibility
   * Reproducible errors
   * Byte-identical binaries


### Prerequisite

A functional [Podman](https://podman.io/) (preferred) or [Docker](https://www.docker.com/) installation is needed.

Within a functional environment this command should drop you in a shell:

    $ docker  run --rm -it paritytech/contracts-ci-linux
    root@00f890cb1ffa:/builds# cargo contract
       Utilities to develop Wasm smart contracts
       ...

### Internals

When launched a first time, a new container is created in the current working directory (*podman run*). This container will auto-destroy after 15min of inactivity. During this period, all commands issued within this directory, will be executed in this container (See [Caveats](#caveats)).

This allows for container filesystem persistency during its lifetime, and thus avoids redownloading cargo dependencies in subsequent runs from the same directory. The overhead of keeping the container running is low in terms of memory and CPU, but gives significant performance improvements in subsequent runs.

See script comments for further details.

### Customization

#### Idle time

By default, the container in CWD is destroyed after **15 mins** of inactivity, this period can be modified here:

    # touch $AFILE with date 15 mins from now
    function touch_agefile() {
        touch --date '15 mins' $AFILE
    }
	
#### Docker image

Currently, [paritytech/contracts-ci-linux:latest](https://hub.docker.com/r/paritytech/contracts-ci-linux) is used, select another image here:

    $ENGINE run --rm --name $CONTAINER_NAME -v .:/builds  \
         paritytech/contracts-ci-linux  bash -c "
	     ...


### Caveats

Only the current working directory is exposed to the container. Thus, it can not traverse to parent directories of your local filesystem. This can be an issue for filesystem dependencies or an upper-level Cargo.toml. The *--manifest-path* option can be used to work around this:

    $ cd openbrush-contracts/
	$ container-contract.sh cargo +nightly contract build --release --manifest-path=examples/psp37_extensions/metadata/Cargo.toml

### Errors

The following error:

    Error: no container with name or ID "cc-728681" found: no such container
	
Indicates that the container has somehow vanished, but the ageing file is still present. This situation can be remediated by removing the ageing file from the current directory:

    rm .container-contract.age-file
