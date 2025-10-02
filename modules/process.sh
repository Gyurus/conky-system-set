#!/bin/bash
# Module for handling Conky processes

kill_conky() {
    echo "🧹 Checking for previous Conky installations..."
    if pgrep -x conky > /dev/null; then
        echo "   ⚠️ Found running Conky processes. Stopping them for clean installation..."
        pkill -TERM -x conky || true
        echo "   ℹ️  If you see a 'Terminated' message above, it is normal: the running Conky process was stopped."
        sleep 2
        if pgrep -x conky > /dev/null; then
            echo "   ⚠️ Forcing Conky processes to stop..."
            pkill -KILL -x conky || true
            echo "   ℹ️  If you see another 'Terminated' message, it is also expected."
        fi
        echo "   ✅ Stopped all running Conky processes."
    fi
}
