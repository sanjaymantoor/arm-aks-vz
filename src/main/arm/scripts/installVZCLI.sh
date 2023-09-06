#

#Function to display usage message
function usage() {
    usage=$(cat <<-END
Usage:
    ./installVZCLI.sh <vz cli url>
END
}

# Main script
export script="${BASH_SOURCE[0]}"
export scriptDir="$(cd "$(dirname "${script}")" && pwd)"

read vzCliDownload

echo "Downloading vz cli"
curl -LO $vzCliDownload
curl -LO ${vzCliDownload}.sha256
sha256sum -c verrazzano-1.6.5-linux-amd64.tar.gz.sha256
