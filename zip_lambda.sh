#! /bin/bash

PIP_PACKAGE_DIR=.package
cd lambdas
# CREATE INFRA

cd create_infra
rm lambda.zip
rm -rf $PIP_PACKAGE_DIR
zip -r9 lambda.zip .


mkdir $PIP_PACKAGE_DIR
pip install -r requirements.txt -t $PIP_PACKAGE_DIR
cd $PIP_PACKAGE_DIR
zip -r9 ../lambda.zip .
cd ../../

# CLOSE TICKET
cd close_ticket
rm lambda.zip
rm -rf $PIP_PACKAGE_DIR
zip -r9 lambda.zip .


mkdir $PIP_PACKAGE_DIR
pip install -r requirements.txt -t $PIP_PACKAGE_DIR
cd $PIP_PACKAGE_DIR
zip -r9 ../lambda.zip .
cd ../