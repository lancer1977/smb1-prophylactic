#!/bin/bash

# SMB Prophylactic - Health Check Script
# Used by Docker health check to verify container health

set -e

# Configuration
MOUNT_POINT="/mnt/legacy-smb"
BRIDGE_SHARE="/srv/smb-bridge"
HEALTH_LOG="/var/log/smb-health.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG"
}

# Check if Samba services are running
check_samba_services() {
    local errors=0
    
    if ! pgrep smbd > /dev/null 2>&1; then
        log "ERROR: smbd is not running"
        errors=$((errors + 1))
    fi
    
    if ! pgrep nmbd > /dev/null 2>&1; then
        log "ERROR: nmbd is not running"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Check if legacy share is mounted
check_mount() {
    if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "ERROR: Legacy SMB share is not mounted"
        return 1
    fi
    
    # Check if mount is accessible
    if [[ ! -d "$MOUNT_POINT" ]] || [[ ! -r "$MOUNT_POINT" ]]; then
        log "ERROR: Legacy SMB share mount is not accessible"
        return 1
    fi
    
    return 0
}

# Check if bridge share is accessible
check_bridge_share() {
    if [[ ! -d "$BRIDGE_SHARE" ]] || [[ ! -r "$BRIDGE_SHARE" ]]; then
        log "ERROR: Bridge share is not accessible"
        return 1
    fi
    
    # Check if bridge share is linked to mount point
    if [[ ! -L "$BRIDGE_SHARE" ]] || [[ "$(readlink "$BRIDGE_SHARE")" != "$MOUNT_POINT" ]]; then
        log "ERROR: Bridge share is not properly linked to mount point"
        return 1
    fi
    
    return 0
}

# Check Samba configuration
check_samba_config() {
    if ! testparm -s > /dev/null 2>&1; then
        log "ERROR: Invalid Samba configuration"
        return 1
    fi
    return 0
}

# Check network connectivity to legacy server
check_network_connectivity() {
    # Extract server IP from environment or config
    local server="${LEGACY_SERVER:-192.168.0.106}"
    
    if ! ping -c 1 -W 3 "$server" > /dev/null 2>&1; then
        log "WARNING: Cannot ping legacy server $server"
        # Don't fail health check for network issues, just log
    fi
    
    return 0
}

# Main health check
main() {
    local errors=0
    
    log "Starting health check..."
    
    # Run all checks
    check_samba_services || errors=$((errors + 1))
    check_mount || errors=$((errors + 1))
    check_bridge_share || errors=$((errors + 1))
    check_samba_config || errors=$((errors + 1))
    check_network_connectivity || errors=$((errors + 1))
    
    if [[ $errors -eq 0 ]]; then
        log "Health check passed"
        exit 0
    else
        log "Health check failed with $errors errors"
        exit 1
    fi
}

# Run health check
main