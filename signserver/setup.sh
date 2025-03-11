#!/bin/bash

# =================================================================
#
#               S I G N   S E R V E R   S E T U P
#
#           Sets up a a sign server instance in docker
#
# -----------------------------------------------------------------

SS_DIR="${HOME}/docker/signserver"

echo "Checking directories..."

if [ ! -d $SS_DIR ]; then

    echo "Settings up directories.."

    mkdir -p "${SS_DIR}/data"
    mkdir -p "${SS_DIR}/certs"
    mkdir -p "${SS_DIR}/logs"

else
    echo "Signserver directory already exists. Skipping this step."
fi

# -----------------------------------------------------------------
#
#               S S L  /  T L S  C E R T I F I C A T E
#
#------------------------------------------------------------------

CERT="${SS_DIR}/certs/codesign.crt"

if [ ! -f $CERT ]; then

    echo -e "No certificate found.\n"
    read -p "Do you wish to create one now? (y/n): " opt

    if [ $opt == "y" ] || [ $opt == "Y" ]; then
        
        # generate private key

        echo "Generating new private key..."
        openssl genpkey -algorithm RSA -out "${SS_DIR}/certs/codesign.key" -aes256

        # generate csr

        echo "Creating the Certificate Signing Request (CSR)..."
        openssl req -new -key "${SS_DIR}/certs/codesign.key"  \
            -out "${SS_DIR}/certs/codesign.csr"               \
            -subj "/C=US/ST=State/L=City/O=FlindDev/CN=CodeSigning"
        
        # self-sign the certificate (no root CA required)

        echo "Self-signing the certificate..."
        openssl x509 -req -in "${SS_DIR}/certs/codesign.csr" \
            -signkey "${SS_DIR}/certs/codesign.key" -out "$CERT" -days 3650

        echo "Self-signed code signing certificate created: $CERT"
    fi
fi

MANAGEMENT_CA="${SS_DIR}/certs/ManagementCA.crt"

# Check if the ManagementCA certificate exists
if [ ! -f "$MANAGEMENT_CA" ]; then

    echo -e "No ManagementCA certificate found.\n"
    read -p "Do you wish to create a self-signed Management CA now? (y/n): " opt

    if [[ $opt == "y" ]] || [[ $opt == "Y" ]]; then

        # Generate private key for Management CA
        echo "Generating private key for Management CA..."
        openssl genpkey -algorithm RSA -out "${SS_DIR}/certs/ManagementCA.key" -aes256

        # Create self-signed root certificate for Management CA
        echo "Creating self-signed Management CA certificate..."
        openssl req -new -key "${SS_DIR}/certs/ManagementCA.key" \
            -out "${SS_DIR}/certs/ManagementCA.csr" \
            -subj "/C=DK/ST=Capital/L=Copenhagen/O=FlindDev/CN=ManagementCA"

        # Self-sign the certificate
        openssl x509 -req -in "${SS_DIR}/certs/ManagementCA.csr" \
            -signkey "${SS_DIR}/certs/ManagementCA.key" -out "$MANAGEMENT_CA" -days 3650

        echo "Self-signed Management CA created: $MANAGEMENT_CA"
    fi
fi


# -----------------------------------------------------------------
#
#                 D O C K E R   C O N T A I N E R
#
#------------------------------------------------------------------

HTTP_PORT=8060
HTTPS_PORT=8444

# pull latest docker image

docker pull keyfactor/signserver-ce

# run container

docker run -it --name signserver                                        \
    -e "SIGNSERVER_UI_USER=admin"                                       \
    -e "SIGNSERVER_UI_PASSWORD=password"                                \
    -p $HTTP_PORT:8080 -p $HTTPS_PORT:8443                              \
    -v ${MANAGEMENT_CA}:/mnt/external/secrets/tls/cas/ManagementCA.crt  \
    -v ${SS_DIR}/data:/mnt/data                                         \
    -v ${SS_DIR}/logs:/mnt/logs                                         \
    -v ${SS_DIR}/certs:/mnt/certs                                       \
    -h signserver.example.com                                           \
    keyfactor/signserver-ce

# cleanup

unset SS_DIR
unset CERT
unset MANAGEMENT_CA
unset HTTP_PORT
unset HTTPS_PORT
