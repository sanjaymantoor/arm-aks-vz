echo "Script ${0} starts"

#Function to display usage message
function usage() {
    usage=$(
        cat <<-END
Specify the following ENV variables:
VZ_CLI_DOWNLOAD
END
    )
    echo_stdout ${usage}
    if [ $1 -eq 0 ]; then
        echo_stderr ${usage}
        exit 1
    fi
}
# Main script
export script="${BASH_SOURCE[0]}"
export scriptDir="$(cd "$(dirname "${script}")" && pwd)"

VZ_CLI_DOWNLOAD=$1

echo "Downloading vz cli"
curl -LO $VZ_CLI_DOWNLOAD
curl -LO ${VZ_CLI_DOWNLOAD}.sha256
fileName=`echo $VZ_CLI_DOWNLOAD | awk -F/ '{print $NF}'`
sha256sum -c ${fileName}.sha256
tar xvf ${fileName}
dirName1=`echo $fileName | cut -f1 -d"-"`
dirName2=`echo $fileName | cut -f2 -d"-"`
dirName=${dirName1}-${dirName2}
cp ${dirName}/bin/vz /usr/local/bin
vz version
