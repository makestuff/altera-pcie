#!/bin/sh
#
# Copyright (C) 2014,2017 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
# the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If
# not, see <http://www.gnu.org/licenses/>.
#
MODULE="fpgalink"
DEVICE="fpga0"
MODE="664"
GROUP="users"

# Go to script directory
cd $(dirname $0)

# Invoke insmod with all arguments we got
/sbin/insmod ./${MODULE}.ko $* || exit 1

# Retrieve major number
MAJOR=$(awk "\$2==\"${DEVICE}\" {print \$1}" /proc/devices)

# Remove stale nodes and replace them, then give gid and perms
rm -f /dev/${DEVICE}
mknod /dev/${DEVICE} c ${MAJOR} 0
chgrp ${GROUP} /dev/${DEVICE}
chmod ${MODE}  /dev/${DEVICE}
