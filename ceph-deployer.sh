#!/bin/bash

# Install ceph-deploy Ubuntu Way
aptitude -y install ceph-deploy

# Add ceph kernel rbd mod repo and install it
echo "[ceph-mod]
name=ceph kmod
baseurl=http://gitbuilder.ceph.com/kmod-rpm-rhel7beta-x86_64-basic/ref/rhel7/x86_64/
enabled=1" > /etc/yum.repos.d/ceph-kmod.repo && yum -y install kmod-rbd

# Install ceph-deploy CentOS Way
echo "[ceph-noarch]
name=Ceph noarch packages
baseurl=http://ceph.com/rpm-firefly/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc" > /etc/yum.repos.d/ceph.repo && yum -y install ceph-deploy
sysctl -w net.ipv6.conf.all.disable_ipv6=1

# Install basic 1 mon/1 osd cluster
mkdir my-cluster
cd my-cluster

ceph-deploy purge `hostname`
ceph-deploy new `hostname`
ceph-deploy install `hostname`

# Tweak the config for minimal setup
echo "
osd pool default size = 1
osd journal size = 1024

#YOUR SETTINGS HERE
debug lockdep = 0/0
debug context = 0/0
debug crush = 0/0
debug buffer = 0/0
debug timer = 0/0
debug journaler = 0/0
debug osd = 0/0
debug optracker = 0/0
debug objclass = 0/0
debug filestore = 0/0
debug journal = 0/0
debug ms = 0/0
debug monc = 0/0
debug tp = 0/0
debug auth = 0/0
debug finisher = 0/0
debug heartbeatmap = 0/0
debug perfcounter = 0/0
debug asok = 0/0
debug throttle = 0/0

" >> ceph.conf


ceph-deploy mon create-initial
ceph-deploy mon create `hostname`
ceph-deploy gatherkeys `hostname`


# Create a 2Gb RAMDisk and use it as OSD (1Gb journal, 1Gb data)
mkdir /tmp/ramdisk
mount -t tmpfs -o size=2g none /tmp/ramdisk
dd if=/dev/zero of=/tmp/ramdisk/myfs.img bs=1M count=2048
losetup /dev/loop0 /tmp/ramdisk/myfs.img
ceph-disk prepare /dev/loop0
ceph-disk activate /dev/loop0p1

# Create 1Gb rbd volume
rbd create --size 1000 rbd/fio_test
rbd map rbd/fio_test

# Install fio
yum -y install fio
aptitude -y install fio

# Run two tests - one on the memory drive itself, one on the rbd mapped disk
# 4k random read, 1 thread
fio --ioengine=libaio --direct=1 --numjobs=1 --rw=randread --runtime=10 --name=fiojob --blocksize=16k --iodepth=1 --filename=/dev/loop0 | tee loop0.fio.log

fio --ioengine=libaio --direct=1 --numjobs=1 --rw=randread --runtime=10 --name=fiojob --blocksize=16k --iodepth=1 --filename=/dev/rbd1 | tee rbd1.fio.log

# Display the results
echo
echo ------------------------------------- RESULTS ---------------------------------------
echo
echo Read speed and IOPS on in-memory block device
egrep "read :" loop0.fio.log
echo
echo
echo Read speed and IOPS on RBD device
egrep "read :" rbd1.fio.log