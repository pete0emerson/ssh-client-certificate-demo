FROM ubuntu:latest

RUN apt-get -y update
RUN apt-get -y install openssh-server

RUN mkdir /var/run/sshd

# Generate a Certificate Authority
RUN ssh-keygen -q -t ed25519 -f /cert_authority -N ''
RUN cp /cert_authority.pub /etc/ssh/trusted_user_ca.pub

# Sign the host keys
RUN ssh-keygen -s /cert_authority \
     -I "Host key" \
     -h \
     /etc/ssh/ssh_host_ed25519_key.pub

RUN echo "HostCertificate /etc/ssh/ssh_host_ed25519_key.pub" >> /etc/ssh/sshd_config
RUN echo "TrustedUserCAKeys /etc/ssh/trusted_user_ca.pub" >>/etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
