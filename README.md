# Explaining the key parts of the Dockerfile

## Install sshd onto stock ubuntu

```
FROM ubuntu:latest

RUN apt-get -y update
RUN apt-get -y install openssh-server

RUN mkdir /var/run/sshd
```

## Generate a certificate authority and copy the public key for SSH to use

```
# Generate a Certificate Authority
RUN ssh-keygen -q -t ed25519 -f /cert_authority -N ''
RUN cp /cert_authority.pub /etc/ssh/trusted_user_ca.pub
```

## Sign the host keys (not really touched on in this demo)

```
# Sign the host keys
RUN ssh-keygen -s /cert_authority \
     -I "Host key" \
     -h \
     /etc/ssh/ssh_host_ed25519_key.pub
```

## Add the host certificate and the trusted user CA keys to the sshd configuration file

```
RUN echo "HostCertificate /etc/ssh/ssh_host_ed25519_key.pub" >> /etc/ssh/sshd_config
RUN echo "TrustedUserCAKeys /etc/ssh/trusted_user_ca.pub" >>/etc/ssh/sshd_config
```

# Build the docker container and run it

```
docker build -f Dockerfile -t ssh:latest .
docker run -p 2222:22 -it --name ssh -d ssh
```

# Create a client certificate

```
mkdir temp
cd temp
ssh-keygen -q -t ed25519 -f ./client -N ''
```

# Push the key into the container, use the certificate authority to sign the client certificate, and pull it back

```
key=$(cat client.pub)
docker exec ssh /bin/bash -c "echo '$key' > /client.pub"
docker exec ssh /bin/bash -c "ssh-keygen -s /cert_authority -I 'client key' -n root -V -5m:+1d /client.pub"
docker exec ssh cat /client-cert.pub > ./client-cert.pub
```

# Fire up an agent and add the private key (the signed cert will be loaded, too)

```
ssh-agent /bin/bash
ssh-add ./client
```

# SSH to the docker container with no public key or password
```
ssh -A -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost
```

# Clean up

```
cd ..
rm -rf temp
docker stop ssh
docker rm ssh
```
