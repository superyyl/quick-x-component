#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
php "$QUICK_V3_ROOT/quick/bin/lib/build_apk.php" -pdir $DIR -classpath ./protocols/android/libPluginProtocol.jar $*
