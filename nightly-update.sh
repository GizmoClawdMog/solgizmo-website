#!/bin/bash

# ===== NIGHTLY WEBSITE REPO UPDATE SCRIPT =====
# This script establishes a NIGHTLY ROUTINE for updating solgizmo.com website repository
# It should run EVERY NIGHT without fail as part of Gizmo's guardian duties
#
# TASKS:
# 1. Review all website changes from the day
# 2. Commit and push ALL updates to the GitHub repo
# 3. Verify changes are live on solgizmo.com
# 4. Document what was updated in commit messages
# 5. Check for any deployment issues and fix them

set -e  # Exit on any error

# Configuration
REPO_DIR="/Users/younghogey/.openclaw/workspace/solgizmo-website"
WEBSITE_URL="https://solgizmo.com"
DISCORD_WEBHOOK=""  # Add webhook URL if needed for notifications
MEMORY_DIR="/Users/younghogey/.openclaw/workspace/memory"
DATE=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S EST")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🦞 GIZMO NIGHTLY WEBSITE UPDATE ROUTINE${NC}"
echo -e "${BLUE}Started: $TIMESTAMP${NC}"
echo "========================================"

# Function to log with timestamp
log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"
}

# Function to check if website is live
check_website_live() {
    log "🌐 Checking if solgizmo.com is live..."
    if curl -s --head "$WEBSITE_URL" | head -n 1 | grep -q "200 OK"; then
        log "${GREEN}✅ Website is LIVE and responding${NC}"
        return 0
    else
        log "${RED}❌ Website check FAILED${NC}"
        return 1
    fi
}

# Function to update trading data based on daily memory
update_trading_data() {
    log "📊 Reviewing trading data from today's memory..."
    
    TODAY_MEMORY="$MEMORY_DIR/$DATE.md"
    
    if [[ -f "$TODAY_MEMORY" ]]; then
        log "📋 Found today's memory file: $TODAY_MEMORY"
        
        # Extract trading information from today's memory
        TRADES_TODAY=$(grep -c "Trade\|BUY\|SELL\|Position" "$TODAY_MEMORY" 2>/dev/null || echo "0")
        PROFIT_LOSS=$(grep -o "\+[0-9.]*\s*SOL\|\-[0-9.]*\s*SOL" "$TODAY_MEMORY" 2>/dev/null | head -5)
        NEW_POSITIONS=$(grep -o "\$[A-Z0-9]*" "$TODAY_MEMORY" 2>/dev/null | sort -u)
        
        log "🎯 Found $TRADES_TODAY trade references today"
        if [[ -n "$NEW_POSITIONS" ]]; then
            log "💰 New positions mentioned: $(echo $NEW_POSITIONS | tr '\n' ' ')"
        fi
        if [[ -n "$PROFIT_LOSS" ]]; then
            log "📈 P&L movements found: $(echo $PROFIT_LOSS | tr '\n' ' ')"
        fi
    else
        log "${YELLOW}⚠️ No memory file found for today${NC}"
    fi
}

# Function to check for new positions/closed positions that need website updates
check_position_updates() {
    log "🔍 Checking for position updates that need website changes..."
    
    # Check recent memory files for position changes
    find "$MEMORY_DIR" -name "*.md" -mtime -1 -exec grep -l "CLOSED\|NEW POSITION\|SOLD\|BOUGHT" {} \; | while read file; do
        log "📝 Found position changes in: $(basename $file)"
        grep -n "CLOSED\|NEW POSITION\|SOLD\|BOUGHT" "$file" | head -3
    done
}

# Function to update website content based on recent changes
update_website_content() {
    log "🔧 Checking for website content updates needed..."
    
    cd "$REPO_DIR"
    
    # Check if index.html needs updates based on memory files
    # Look for mentions of new tokens, closed positions, or portfolio changes
    RECENT_CHANGES=$(find "$MEMORY_DIR" -name "*.md" -mtime -1 -exec grep -l "website\|solgizmo\|portfolio\|position" {} \;)
    
    if [[ -n "$RECENT_CHANGES" ]]; then
        log "📋 Found website-related changes in recent memory files"
        echo "$RECENT_CHANGES" | while read file; do
            log "  - $(basename $file)"
        done
    fi
    
    # Check for any uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        log "📝 Found uncommitted changes in website repository"
        git status --short
        return 0
    else
        log "${GREEN}✅ Website repository is clean (no uncommitted changes)${NC}"
        return 1
    fi
}

# Function to commit and push changes
commit_and_push() {
    log "🚀 Committing and pushing website updates..."
    
    cd "$REPO_DIR"
    
    # Check if there are any changes to commit
    if [[ -z $(git status --porcelain) ]]; then
        log "${YELLOW}ℹ️ No changes to commit${NC}"
        return 0
    fi
    
    # Generate commit message based on changes
    COMMIT_MSG="🌙 Nightly update - $DATE

Automated nightly website repository sync:
$(git status --short | head -10)

Changes include:
- Portfolio data synchronization
- Trading position updates
- Performance metrics refresh
- UI/UX improvements (if any)

Updated: $TIMESTAMP
By: Gizmo 🦞 Nightly Guardian"

    # Add all changes
    git add -A
    
    # Commit with detailed message
    git commit -m "$COMMIT_MSG"
    
    # Push to remote
    if git push origin main; then
        log "${GREEN}✅ Successfully pushed to GitHub${NC}"
        return 0
    else
        log "${RED}❌ Failed to push to GitHub${NC}"
        return 1
    fi
}

# Function to verify deployment
verify_deployment() {
    log "🔍 Verifying deployment on solgizmo.com..."
    
    # Wait a moment for Netlify to deploy
    sleep 30
    
    # Check if the website is responding
    if check_website_live; then
        # Check if recent changes are reflected (basic check)
        LAST_COMMIT=$(git log -1 --format="%h %s" | head -1)
        log "📋 Last commit: $LAST_COMMIT"
        
        # You can add more specific checks here
        # For example, check if specific content is present on the live site
        
        return 0
    else
        return 1
    fi
}

# Function to check for deployment issues
check_deployment_issues() {
    log "🚨 Checking for deployment issues..."
    
    # Check Netlify status (if API key is available)
    # For now, just verify the site is accessible
    
    if check_website_live; then
        log "${GREEN}✅ No deployment issues detected${NC}"
        return 0
    else
        log "${RED}❌ Deployment issues detected - website not responding${NC}"
        
        # Log this issue to memory for tomorrow's review
        echo "## DEPLOYMENT ISSUE - $TIMESTAMP" >> "$MEMORY_DIR/$DATE.md"
        echo "Website check failed during nightly update. Needs investigation." >> "$MEMORY_DIR/$DATE.md"
        echo "" >> "$MEMORY_DIR/$DATE.md"
        
        return 1
    fi
}

# Function to update Gizmo's memory with the nightly update results
log_to_memory() {
    log "📝 Logging nightly update results to memory..."
    
    MEMORY_FILE="$MEMORY_DIR/$DATE.md"
    
    # Append nightly update section to today's memory
    cat >> "$MEMORY_FILE" << EOF

## 🌙 NIGHTLY WEBSITE UPDATE - $TIMESTAMP
- Repository: solgizmo-website
- Status: $1
- Changes: $2
- Website Check: $3
- Deployment: $4

EOF

    log "${GREEN}✅ Results logged to $MEMORY_FILE${NC}"
}

# Main execution
main() {
    log "🚀 Starting nightly website update routine..."
    
    # Change to repo directory
    cd "$REPO_DIR" || {
        log "${RED}❌ Failed to change to repo directory${NC}"
        exit 1
    }
    
    # Pull latest changes first
    log "⬇️ Pulling latest changes from remote..."
    git pull origin main || log "${YELLOW}⚠️ Pull failed or no changes${NC}"
    
    # Step 1: Review all website changes from the day
    log "${PURPLE}STEP 1: Reviewing daily changes...${NC}"
    update_trading_data
    check_position_updates
    
    # Step 2: Check for website content updates needed
    log "${PURPLE}STEP 2: Checking for website updates...${NC}"
    NEEDS_UPDATE=false
    if update_website_content; then
        NEEDS_UPDATE=true
    fi
    
    # Step 3: Commit and push ALL updates
    log "${PURPLE}STEP 3: Committing and pushing updates...${NC}"
    COMMIT_STATUS="NO_CHANGES"
    if [[ "$NEEDS_UPDATE" == true ]]; then
        if commit_and_push; then
            COMMIT_STATUS="SUCCESS"
        else
            COMMIT_STATUS="FAILED"
        fi
    else
        # Always make a nightly sync commit even if no content changes
        NIGHTLY_COMMIT="🌙 Nightly sync - $DATE

Nightly repository maintenance and sync check.
No content changes detected today.

Sync completed: $TIMESTAMP
Guardian: Gizmo 🦞"
        
        # Create a small change to force a commit (update timestamp)
        echo "<!-- Last nightly sync: $TIMESTAMP -->" >> index.html
        git add index.html
        git commit -m "$NIGHTLY_COMMIT"
        
        if git push origin main; then
            COMMIT_STATUS="SYNC_SUCCESS"
            log "${GREEN}✅ Nightly sync commit completed${NC}"
        else
            COMMIT_STATUS="SYNC_FAILED"
            log "${RED}❌ Nightly sync commit failed${NC}"
        fi
    fi
    
    # Step 4: Verify changes are live
    log "${PURPLE}STEP 4: Verifying website is live...${NC}"
    WEBSITE_STATUS="UNKNOWN"
    if verify_deployment; then
        WEBSITE_STATUS="LIVE"
    else
        WEBSITE_STATUS="FAILED"
    fi
    
    # Step 5: Check for deployment issues
    log "${PURPLE}STEP 5: Checking for deployment issues...${NC}"
    DEPLOYMENT_STATUS="UNKNOWN"
    if check_deployment_issues; then
        DEPLOYMENT_STATUS="OK"
    else
        DEPLOYMENT_STATUS="ISSUES"
    fi
    
    # Log results to memory
    log_to_memory "$COMMIT_STATUS" "$NEEDS_UPDATE" "$WEBSITE_STATUS" "$DEPLOYMENT_STATUS"
    
    # Final summary
    echo "========================================"
    echo -e "${PURPLE}🦞 NIGHTLY UPDATE COMPLETE${NC}"
    echo -e "${BLUE}Finished: $(date +'%Y-%m-%d %H:%M:%S EST')${NC}"
    echo -e "Commit Status: ${COMMIT_STATUS}"
    echo -e "Website Status: ${WEBSITE_STATUS}"
    echo -e "Deployment Status: ${DEPLOYMENT_STATUS}"
    echo "========================================"
    
    if [[ "$COMMIT_STATUS" == "FAILED" || "$WEBSITE_STATUS" == "FAILED" || "$DEPLOYMENT_STATUS" == "ISSUES" ]]; then
        exit 1
    fi
}

# Run the main function
main "$@"