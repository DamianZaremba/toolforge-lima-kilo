# Toolforge lima kilo

This is a repository that contains logic to setup a fake Toolforge kubernetes
environment in a given machine.

A *L*ocal *K*ubernetes deployment to help develop some of the Toolforge internal
components.

The only supported way to run it is inside a lima-vm virtual machine, use at
your own risk outside of one (might mess up your installation).

## How to use it

Install Lima by following the instructions provided in the
[official Lima-VM installation guide](https://lima-vm.io/docs/installation/).

On Mac, it can be installed using `brew`. On Linux you need to follow the
instructions on the `Binary` or `Source` section of the installation guide
above. **Note:** that if you are using the `Binary` method on linux you'll need
to make a few modifications like installing jq with apt-get. other than that
everything should work the same.

Then run `./start-devenv.sh`

There is an option to copy dotfiles from the host to the home directory (~) of
the lima-kilo VM. Use the command as follows:

```bash
$ ./start-devenv.sh --dotfiles <path-to-dotfiles>
```

You can also specify the dotfiles dir relative to the /lima-vm/dotfiles folder:

```bash
$ ./start-devenv.sh --dotfiles user
```

If the --dotfiles flag is not provided, the script defaults to using the
LIMA_KILO_DOTFILES environment variable, if set:

```bash
$ export LIMA_KILO_DOTFILES=user
```

See detailed instructions here: [LimaVM README](./lima-vm/README.md)

## Usage

Once the installation is finished, you can run commands inside the vm as one of
the two default users created, tf-test or tf-test2 like this:

```bash
user@lima-kilo$ become tf-test
local.tf-test@lima-kilo:~$ pwd
/data/project/tf-test
```

You would be already at the home of the user, and ready to run any toolforge
commands.

## Extra tools

Some extra tools are also installed:

- k9s to explore/manage kubernetes
- jq
- fzf
- htop
- tcpdump
- kubectl
- helm
- helmfile
- docker-compose to manage harbor
- any toolforge\_\* script, among them:
  - toolforge_deploy_mr.py to deploy the CI-generated artifacts from the given
    toolforge component MR (will show a list of none passed)
  - helper script toolforge_harbor_compose.sh, to manage harbor (wrapper around
    docker-compose)

There's also a clone of `toolforge-deploy` and a mount of `lima-kilo` in the
home of the default user `~/{lima-kilo,toolforge-deploy}`.

## Debugging tips

### API gateway

If you want to access directly the api-gateway, you can do so by pointing to
`https://127.0.0.1:30003/`, note that you will need the user certs to
authenticate:

```bash
local.tf-test@vulcanus:~$ curl --insecure --cert ~/.toolskube/client.crt --key ~/.toolskube/client.key https://127.0.0.1:30003/
This is the Toolforge API gateway!
```

Another example, to hit the jobs-api by hand:

```bash
local.tf-test@lima-kilo:~$ curl https://localhost:30003/jobs/api/v1/jobs/ --cert .toolskube/client.crt --key .toolskube/client.key -k --header "Content-Type: application/json" -X POST --data '{"name":"test","image":"bookworm","cmd":"./test-cmd.sh"}'
```

### Tool webservices

You can reach the tools webservice endpoints by curling to the address (ex. for
`tf-test` tool):

```
local.tf-test@lima-kilo:~$ curl http://tf-test.local:30002/
```

## Running functional tests

To run the functional tests, you can use the script
`toolforge_run_functional_tests.sh`, it takes some time though (as it depends on
k8s and does not run in parallel). You can run it from your user account:

```bash
dcaro@lima-kilo$ toolforge_run_functional_tests.sh -- --filter '.*continuous.*'
jobs-api/continuous-job-healthcheck.bats
 ✓ run a continuous job with script healthcheck passing [4210]
 ✓ run a continuous job with script healthcheck failing [15064]
jobs-api/continuous-job-port.bats
 ✓ run a continuous job without port shows no port [6865]
 ✓ run a continuous job with a port shows port [6451]
 ✓ run a continuous job with a port exposes port [17935]
jobs-api/continuous-job-smoke-test.bats
 ✓ run a simple continuous job [4169]

6 tests, 0 failures in 55 seconds
```

You can also filter which tests you want to run (see
`toolforge_run_functional_tests.sh --help`).

## License

[GPL-3.0](//www.gnu.org/copyleft/gpl.html "GPL-3.0")
