#!/bin/bash

BUCKET_NAME=apse2-$1-digitalcerts-inbound
DEPLOYABLE_FOLDER=code-deployables
DEPLOYABLE_NAME=digitalcertificate-prod.zip
TMP_DIR=/tmp

CODE_DIR=/var/digitalcertificates


# stage old deployable if any
TIMESTAMP=$(date +%FT%T%Z)

if [ -f "$TMP_DIR/$DEPLOYABLE_NAME" ]; then
    mv $TMP_DIR/$DEPLOYABLE_NAME $TMP_DIR/$TIMESTAMP-$DEPLOYABLE_NAME
fi

# pull down code deployable from s3
aws s3 cp s3://$BUCKET_NAME/$DEPLOYABLE_FOLDER/$DEPLOYABLE_NAME $TMP_DIR/$DEPLOYABLE_NAME

# remove old folder if any
sudo rm -rf $CODE_DIR
sudo mkdir $CODE_DIR

sudo chmod -R 777 $CODE_DIR

# extract code
unzip $TMP_DIR/$DEPLOYABLE_NAME -d $CODE_DIR

# substitute variables
sed -i -e 's/^\(POPPLER_BIN_DIR: \).*$/\1\/opt\/poppler-0.47\/bin/' $CODE_DIR/digitalcertificate/prod.yml
sed -i -e 's/^\(AWS_ENVIRONMENT: \).*$/\1'$1'/' $CODE_DIR/digitalcertificate/prod.yml
sed -i -e 's/^\(DEBUG = \).*$/\1False/' $CODE_DIR/digitalcertificate/settings.py

# use python35 context to run engine
echo "Running parser"
CODE_DIR=$CODE_DIR scl enable rh-python35 'python $CODE_DIR/main.py'
