FROM af6140/cent7-nifi:latest


USER root

RUN rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && \
    yum update -y && \
    yum install -y openssh-server curl gcc git make rpm-build ruby ruby-devel tar sensu sudo which yum-plugin-versionlock && \
    yum versionlock puppet* && \
    systemctl enable sshd && \
    echo "gem: --no-ri --no-rdoc" > /etc/gemrc && \
    yum clean all

ENTRYPOINT ["/sbin/init"]
