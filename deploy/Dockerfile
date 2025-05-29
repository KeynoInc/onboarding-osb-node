# Use the official Node.js image as the base image
FROM node:20 as builder

RUN apt-get update

RUN apt-get install -y jq

RUN node -version

RUN curl -sL https://raw.githubusercontent.com/IBM-Cloud/ibm-cloud-developer-tools/master/linux-installer/idt-installer | bash \
 && ibmcloud plugin install code-engine