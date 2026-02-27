#!/bin/bash

# SMB Prophylactic - Protocol Bridge Startup Script
# This script starts the SMB protocol bridge service

set -euo pipefail

# Configuration
LEGACY_SERVER="${LEGACY_SERVER:-192.168.0.106}"
LEGACY_SHARE="${LEGACY_SHARE:-share}"
MOUNT_POINT="/mnt/legacy-smb"
BRIDGE_SHARE="/srv/smb-bridge"
LOG_FILE="/var/log/smb-prophylactic.log"
PID_FILE="/var/run/smb-prophylactic.pid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    log "${YELLOW}Cleaning up...${NC}"
    
    # Stop Samba services
    if pgrep smbd > /dev/null 2>&1; then
        log "Stopping smbd..."
        pkill smbd || true
    fi
    
    if pgrep nmbd > /dev/null 2>&1; then
        log "Stopping nmbd..."
        pkill nmbd || true
    fi
    
    # Unmount legacy share
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "Unmounting legacy SMB share..."
        umount "$MOUNT_POINT" || log "Warning: Failed to unmount legacy share"
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    log "${GREEN}Cleanup complete${NC}"
}

# Signal handlers
trap cleanup SIGTERM SIGINT

# Function to mount legacy SMB share
mount_legacy_smb() {
    log "${YELLOW}Mounting legacy SMB share from $LEGACY_SERVER...${NC}"
    
    # Create mount point if it doesn't exist
    mkdir -p "$MOUNT_POINT"
    
    # Check if already mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "${GREEN}Legacy share already mounted${NC}"
        return 0
    fi
    
    # Mount the legacy SMB share with SMB1
    if mount -t cifs "//$LEGACY_SERVER/$LEGACY_SHARE" "$MOUNT_POINT" \
        -o guest,vers=1.0,uid=samba,gid=samba,iocharset=utf8,noperm,cache=none; then
        log "${GREEN}Successfully mounted legacy SMB share${NC}"
    else
        error_exit "Failed to mount legacy SMB share from $LEGACY_SERVER"
    fi
    
    # Create symbolic link to the bridge share
    ln -sf "$MOUNT_POINT" "$BRIDGE_SHARE"
    
    log "${GREEN}Legacy SMB share mounted and linked${NC}"
}

# Function to start Samba services
start_samba() {
    log "${YELLOW}Starting Samba services...${NC}"
    
    # Create necessary directories
    mkdir -p /var/run/samba
    mkdir -p /var/lib/samba
    
    # Start nmbd (NetBIOS name service)
    log "Starting nmbd..."
    nmbd -D --pidfile /var/run/nmbd.pid
    
    # Start smbd (SMB daemon)
    log "Starting smbd..."
    smbd -D --pidfile /var/run/smbd.pid
    
    # Verify services started
    sleep 2
    if ! pgrep smbd > /dev/null 2>&1 || ! pgrep nmbd > /dev/null 2>&1; then
        error_exit "Failed to start Samba services"
    fi
    
    log "${GREEN}Samba services started successfully${NC}"
}

# Function to verify configuration
verify_config() {
    log "${YELLOW}Verifying configuration...${NC}"
    
    # Check if Samba configuration is valid
    if ! testparm -s > /dev/null 2>&1; then
        error_exit "Invalid Samba configuration"
    fi
    
    # Check if required directories exist
    if [[ ! -d "$BRIDGE_SHARE" ]]; then
        mkdir -p "$BRIDGE_SHARE"
        chown samba:samba "$BRIDGE_SHARE"
    fi
    
    log "${GREEN}Configuration verification complete${NC}"
}

# Function to run health check
health_check() {
    # Check if Samba services are running
    if ! pgrep smbd > /dev/null 2>&1 || ! pgrep nmbd > /dev/null 2>&1; then
        log "${RED}Samba services not running, attempting restart...${NC}"
        cleanup
        sleep 2
        start_samba
        return $?
    fi
    
    # Check if legacy share is mounted
    if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "${RED}Legacy share not mounted, attempting remount...${NC}"
        cleanup
        sleep 2
        mount_legacy_smb
        return $?
    fi
    
    return 0
}

# Function to show status
show_status() {
    log "${BLUE}=== SMB Prophylactic Status ===${NC}"
    log "Legacy Server: $LEGACY_SERVER"
    log "Legacy Share: $LEGACY_SHARE"
    log "Mount Point: $MOUNT_POINT"
    log "Bridge Share: $BRIDGE_SHARE"
    log ""
    
    # Check services
    if pgrep smbd > /dev/null 2>&1; then
        log "${GREEN}✓ smbd is running${NC}"
    else
        log "${RED}✗ smbd is not running${NC}"
    fi
    
    if pgrep nmbd > /dev/null 2>&1; then
        log "${GREEN}✓ nmbd is running${NC}"
    else
        log "${RED}✗ nmbd is not running${NC}"
    fi
    
    # Check mount
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "${GREEN}✓ Legacy share is mounted${NC}"
    else
        log "${RED}✗ Legacy share is not mounted${NC}"
    fi
    
    log "${BLUE}=== End Status ===${NC}"
}

# Main execution
main() {
    log "${GREEN}Starting SMB Prophylactic Bridge...${NC}"
    log "Legacy Server: $LEGACY_SERVER"
    log "Legacy Share: $LEGACY_SHARE"
    
    # Verify configuration
    verify_config
    
    # Mount legacy SMB share
    mount_legacy_smb
    
    # Start Samba services
    start_samba
    
    # Write PID file
    echo $$ > "$PID_FILE"
    
    log "${GREEN}SMB Prophylactic Bridge is running${NC}"
    log "Press Ctrl+C to stop"
    
    # Keep container running and perform health checks
    while true; do
        sleep 30
        
        # Perform health check
        if ! health_check; then
            log "${RED}Health check failed, exiting...${NC}"
            cleanup
            exit 1
        fi
        
        # Show periodic status (every 10 minutes)
        if (( $(date +%M) % 10 == 0 && $(date +%S) < 5 )); then
            show_status
        fi
    done
}

# Handle command line arguments
case "${1:-start}" in
    "start")
        main
        ;;
    "status")
        show_status
        ;;
    "test")
        log "${YELLOW}Testing SMB connection...${NC}"
        mount_legacy_smb
        start_samba
        sleep 5
        show_status
        cleanup
        ;;
    *)
        echo "Usage: $0 {start|status|test}"
        exit 1
        ;;
esac