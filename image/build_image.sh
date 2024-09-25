
set -x -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

PACKER_VERSION="1.11.2"


pushd $SCRIPTPATH

if [ ! -f ./packer ]; then
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip;
    unzip packer_${PACKER_VERSION}_linux_arm64.zip;
    rm packer_${PACKER_VERSION}_linux_arm64.zip;
fi


# Store the configuration file name from the command line argument
config_file=$SCRIPTPATH/ubuntu.pkr.hcl


if [ ! -f ./flash0.img ]; then
    cp /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ./flash0.img
    truncate -s 64M flash0.img
fi



# Check if the specified configuration file exists
if [ -f "$config_file" ]; then
    # Install the needed plugins
    ./packer init "$config_file"
    # Build the image
    ./packer build "$config_file"
else
    echo "Error: Configuration file '$config_file' not found."
    exit 1
fi

popd