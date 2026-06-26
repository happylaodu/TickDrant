# Long-term Strategy - Tickdrant

## Product Vision

A lightweight, native macOS countdown timer app focused on deadline management with recurring task support. Differentiator: Simple, privacy-first, native performance.

## Market Positioning

**Target Users:**
- Project managers tracking multiple deadlines
- Students managing assignment due dates
- Freelancers with client deliverables
- Anyone who needs deadline reminders with recurring tasks

**Competitive Advantage:**
- Native Swift/SwiftUI (better performance than Electron apps)
- Recurring tasks support (not common in simple countdown apps)
- Privacy-first (local data storage)
- One-time purchase model (no subscription fatigue)

## Development Roadmap

### Phase 1: Core Features (2-4 weeks)
**Goal:** Make the app feature-complete and App Store ready

**P0 - Must Have:**
- [ ] **Notifications** - Alert users before tasks are due
  - 5 minutes, 1 hour, 1 day before due date
  - User-configurable notification times
  - Request notification permissions
- [ ] **Menu Bar Support** (Idea #1)
  - Menu bar icon with countdown display
  - Quick access to tasks from menu bar
  - User preference: Dock only, Menu Bar only, or both
- [ ] **Settings Window** (Idea #5)
  - Launch at login option
  - Notification preferences
  - Display location preference (Dock/Menu Bar)
  - Default recurrence intervals
- [ ] **Data Backup/Export**
  - Export tasks to JSON
  - Import from JSON
  - Auto-backup to prevent data loss

**P1 - Should Have:**
- [ ] **UI Improvements** (Idea #6)
  - Replace Edit/Delete buttons with SF Symbols icons
  - Improve visual hierarchy
  - Add keyboard shortcuts
- [ ] **Task Comments** (Idea #3)
  - Optional note field for each task
  - Display in task panel or tooltip
- [ ] **Dark Mode Optimization**
  - Test and refine dark mode appearance
  - Ensure proper contrast

### Phase 2: Polish & Release (1-2 weeks)
**Goal:** Prepare for public release

- [ ] **App Store Assets**
  - Screenshots (light & dark mode)
  - App description & keywords
  - Privacy policy (if collecting any data)
  - App icon validation ✅
- [ ] **Testing**
  - Test on multiple macOS versions (13.0+)
  - Test on Intel and Apple Silicon
  - Bug fixes and edge cases
- [ ] **Documentation**
  - User guide / README
  - In-app help/tutorial
  - FAQ for common questions

### Phase 3: Initial Release (1 week)
**Goal:** Get product into users' hands

**Release Strategy: Free + Open Source**
- App Store: Free (no ads, no IAP initially)
- GitHub: Open source under MIT License
- Focus on gathering feedback and building user base

**Launch Channels:**
1. App Store submission
2. GitHub release with documentation
3. Product Hunt launch
4. Reddit r/macapps post
5. Hacker News "Show HN" post
6. macOS productivity blogs outreach

**Success Metrics:**
- 100+ downloads in first month
- 4.0+ star rating on App Store
- 10+ GitHub stars
- User feedback and feature requests

### Phase 4: Iteration (Ongoing)
**Goal:** Improve based on user feedback

**High Priority Features (based on feedback):**
- [ ] iCloud Sync (if users request it)
- [ ] macOS Widgets
- [ ] Task categories/tags
- [ ] Search and filtering
- [ ] Batch operations
- [ ] Custom themes

**Long-term Considerations:**
- [ ] **Multi-user Collaboration** (Idea #4)
  - Only if there's significant user demand
  - Requires backend infrastructure
  - Consider partnership or paid tier
- [ ] **iOS/iPadOS Version**
  - Share codebase with SwiftUI
  - Universal purchase option
- [ ] **Pro Version**
  - If user base grows to 1000+ active users
  - Advanced features: unlimited tasks, cloud sync, team features
  - Pricing: $4.99-$9.99 one-time or $1.99/month

## Business Model Evolution

### Current: Free + Open Source
- No monetization
- Build user base and reputation
- Collect feedback

### Future Option A: Freemium (if demand exists)
- Free: Up to 10 tasks, local storage
- Pro: Unlimited tasks, iCloud sync, widgets, priority support
- Pricing: $4.99 one-time or $1.99/month

### Future Option B: Donation/Tip Jar
- Keep free and open source
- Optional donations via Buy Me a Coffee or GitHub Sponsors
- Community-driven development

### Future Option C: Portfolio Project
- Keep entirely free
- Use for resume and portfolio
- No monetization focus

**Current Recommendation:** Start with Option C (Portfolio Project), evaluate Option B (Donations) after 6 months if user base grows.

## Risk Assessment

**High Risk:**
- App Store rejection (ensure compliance with guidelines)
- Low adoption (crowded market)
- Maintenance burden (ongoing support needed)

**Mitigation:**
- Follow App Store guidelines strictly
- Focus on unique features (recurring tasks)
- Automate testing and releases
- Set clear boundaries on support time

**Exit Strategy:**
- If low adoption after 6 months: Keep online but minimal maintenance
- If negative ROI on time: Open source and archive
- If successful: Consider gradual feature expansion

## Decision Points

**After Phase 3 (3 months post-launch):**
- [ ] Evaluate download numbers (target: 100+)
- [ ] Review user feedback and ratings
- [ ] Decide: Continue development, maintain as-is, or archive

**After 6 Months:**
- [ ] Assess active user base
- [ ] Evaluate monetization options
- [ ] Decide on long-term investment level

**After 1 Year:**
- [ ] Consider iOS version if Mac version successful
- [ ] Evaluate Pro version viability
- [ ] Long-term roadmap decision

## Notes

- Keep scope manageable - avoid feature creep
- Prioritize user feedback over planned features
- Don't invest more than 2-3 hours/week after initial release
- Success = learning experience + portfolio piece, not revenue

---

**Last Updated:** 2026-03-08
**Status:** Phase 1 - In Development
**Next Milestone:** Complete Idea #1 (Menu Bar) and Idea #5 (Settings)
