#!/bin/sh

print_usage () {
	echo ""
	echo "Usage: $1 [-x]" >&2
	echo "  $1 will install open-vm-tools-nox11."
	echo "  $1 -x will install open-vm-tools."
	echo ""
}

#----------------------------------------------
x11=0
option_info="$*"
while getopts hx o; do
	case "$o" in
	h)    print_usage "$0"
		exit 0;;
	x)    x11=1;;
        [?])  print_usage "$0"
              exit 1;;
      esac
done
shift $((OPTIND-1))

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
	       enabled: YES
	   }
EOF

env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg update
if [ ${x11} -eq 1 ]; then
	env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install -r vmtools open-vm-tools
else
	env ASSUME_ALWAYS_YES=yes /usr/sbin/pkg install -r vmtools open-vm-tools-nox11
fi

if [ -f /etc/rc.conf ]; then
	grep -q vmware_guest /etc/rc.conf
	if [ $? -ne 0 ]; then
		setup_rcconf
	fi
else
	setup_rcconf
fi
