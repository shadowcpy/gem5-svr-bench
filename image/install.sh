
set -x -e

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

PACKER_VERSION="1.11.2"



if [ ! -f ./packer ]; then
    wget https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_arm64.zip;
    unzip packer_${PACKER_VERSION}_linux_arm64.zip;
    rm packer_${PACKER_VERSION}_linux_arm64.zip;
fi



# Store the configuration file name from the command line argument
config_file=$SCRIPTPATH/benchmarks.pkr.hcl


make -f $SCRIPTPATH/arm.Makefile build-wkdir


# if [ ! -f $WK_CLIENT ]; then
    
#     ## Make a copy of the disk image
#     pushd ../client
#     ARCH=arm64 make all
#     popd
#     cp ../client/http-client $WK_CLIENT

# fi


make -f $SCRIPTPATH/arm.Makefile  run 1> qemu.log 2>&1 &

QEMU_PID=$!
echo "QEMU PID: $QEMU_PID"





# Wait for the QEMU process to finish
sleep 1s


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


# Wait for the QEMU process to finish
wait $QEMU_PID
# sleep 2s