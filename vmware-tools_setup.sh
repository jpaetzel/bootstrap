#!/bin/sh

setup_rcconf()
{
	echo 'vmware_guest_vmblock_enable="YES"' >> /etc/rc.conf
	echo 'vmware_guest_vmmemctl_enable="YES"' >> /etc/rc.conf
	echo 'vmware_guest_vmxnet_enable="YES"' >> /etc/rc.conf
	echo 'vmware_guestd_enable="YES"' >> /etc/rc.conf
}

mkdir -p /usr/local/etc/pkg/repos
rm /usr/local/etc/pkg/repos/*

if ! [ -f /usr/local/sbin/pkg ]; then
	env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg bootstrap
fi

pkg info ca_root_nss > /dev/null
if [ $? -ne 0 ]; then
	env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install ca_root_nss-3.32
fi

cat > /usr/local/etc/pkg/repos/vmtools.conf <<EOF
	   vmtools: {
	       url: "https://people.freebsd.org/~jpaetzel/pkg/$(uname -s):$(uname -r | awk -F. '{print $1}'):$(uname -m)"
	       SIGNATURE_TYPE: none
	       MIRROR_TYPE: none
	   }
EOF

cat > /usr/local/etc/pkg/repos/FreeBSD.conf <<EOF
	   FreeBSD: {
	       enabled: NO
	   }
EOF

env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg update
env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install open-vm-tools-nox11

if [ -f /etc/rc.conf ]; then
	grep -q vmware_guest /etc/rc.conf
	if [ $? -ne 0 ]; then
		setup_rcconf
	fi
else
	setup_rcconf
fi
