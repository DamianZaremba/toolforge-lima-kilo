# Lima Installation and Testing Guide

This is a basic guide on how to install and test on Lima.

## Installation

1. Install Lima by following the instructions provided in the [official Lima-VM documentation](https://github.com/lima-vm/lima).

On Mac, it can be installed using `brew`. Otherwise, you need to clone the repo and install with `make`.

## Testing

1. Create a new VM from the `bookworm.yaml` template:

   ```bash
   limactl start bookworm.yaml
   ```

2. Start the VM:

   ```bash
   limactl start bookworm
   ```

3. Get a shell in the VM:

   ```bash
   limactl shell bookworm
   ```

4. Run the `prepare.sh`, `install.sh`, and `run.sh` scripts in that order:

   ```bash
   ./prepare.sh
   ./install.sh
   ./run.sh
   ```

5. Make sure you can run a build successfully.
