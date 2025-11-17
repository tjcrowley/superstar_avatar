# Goldfire Phase 1 Integration - Basic Activities

This document describes the integration of the Goldfire Activity Types system into the SUPERSTAR AVATAR decentralized application.

## Overview

The Goldfire system provides 7 foundational Activity Types that serve as the core primitives for the Activity Authoring Feature in Phase 1. Each activity must declare one Activity Type and can associate with one or more of the 5 Powers.

## Activity Types

### 1. Personal Resources
**Icon:** 📋  
**Color:** Indigo (#6366F1)  
**Description:** Self-assessment activities focusing on personal traits, skills, values, projects, and growth edges.

**Use Cases:**
- Skills inventory
- Values clarification
- Project planning
- Growth edge identification
- Personal reflection

### 2. Introductions
**Icon:** 👋  
**Color:** Blue (#3B82F6)  
**Description:** Activities that support making authentic connections between participants.

**Use Cases:**
- Icebreakers
- Networking activities
- Community building
- Relationship initiation

### 3. Dynamics
**Icon:** ⚡  
**Color:** Purple (#8B5CF6)  
**Description:** Guidelines, tips, and structured activities created by experience designers to promote prosocial behavior.

**Use Cases:**
- Team building exercises
- Conflict resolution activities
- Communication workshops
- Group facilitation

### 4. Locales
**Icon:** 📍  
**Color:** Green (#10B981)  
**Description:** Defines a physical or conceptual Location ("Locale") and any activities associated with it.

**Use Cases:**
- Event-specific zones
- Thematic spaces
- Location-based tasks
- Venue exploration

### 5. Mythic Lens
**Icon:** 🔮  
**Color:** Amber (#F59E0B)  
**Description:** Activities designed to refine interactions or inquiries by applying symbolic, archetypal, or narrative-based perspectives.

**Use Cases:**
- Archetypal exploration
- Symbolic interpretation
- Narrative reframing
- Mythological storytelling

### 6. Alchemy
**Icon:** ✨  
**Color:** Red (#EF4444)  
**Description:** Activities that put kindness, empathy, and virtuosity into action.

**Use Cases:**
- Acts of service
- Compassionate engagement
- Altruistic actions
- Community support

### 7. Tales
**Icon:** 📖  
**Color:** Cyan (#06B6D4)  
**Description:** Stories associated with activities, houses, avatars, powers, or locales. Tales may be authored manually or generated as emergent narrative records.

**Use Cases:**
- Activity narratives
- House stories
- Avatar journeys
- Power legends
- Location histories

## Power Associations

All Activity Types must be configurable to associate with one or more of the 5 Powers:

1. **Courage** 🦁 - Facing fears and taking bold actions
2. **Creativity** 🎨 - Thinking outside the box and innovation
3. **Connection** 🤝 - Building meaningful relationships
4. **Insight** 🔍 - Understanding others deeply
5. **Kindness** 💝 - Showing compassion and support

### Power Association Rules:
- **Primary Power** (Required): One power must be designated as primary
- **Secondary Powers** (Optional): Up to 4 additional powers can be associated
- All power associations are visible in the UI
- Power associations are stored in the data schema
- Power associations are referenced in smart contracts for verification and progression

## Architecture Integration

### Smart Contract Layer (`ActivityScripts.sol`)

```solidity
enum ActivityType {
    PersonalResources,
    Introductions,
    Dynamics,
    Locales,
    MythicLens,
    Alchemy,
    Tales
}

struct ActivityScript {
    string id;
    string title;
    string description;
    string instructions;
    ActivityType activityType;  // Required
    PowerType primaryPower;      // Required
    PowerType[] secondaryPowers;  // Optional (max 4)
    // ... other fields
    string metadata;             // For Tales, narrative, etc.
    string authorId;             // Avatar ID or House ID
    string decentralizedStorageRef; // IPFS hash
}
```

### Data Model (`activity_script.dart`)

```dart
enum ActivityType {
  personalResources,
  introductions,
  dynamics,
  locales,
  mythicLens,
  alchemy,
  tales,
}

class ActivityScript {
  final ActivityType activityType;  // Required
  final PowerType primaryPower;     // Required
  final List<PowerType> secondaryPowers;  // Optional (max 4)
  final List<PowerType> targetPowers;    // Computed: primary + secondary
  final String? decentralizedStorageRef; // IPFS hash
  final Map<String, dynamic> metadata;   // For Tales, narrative
  // ... other fields
}
```

### UI Components

1. **Activity Authoring Screen** (`activity_authoring_screen.dart`)
   - Activity Type selector with visual indicators
   - Primary Power selector (required)
   - Secondary Power selector (optional, up to 4)
   - Activity settings (difficulty, duration, experience)
   - Metadata fields for Tales and narrative content

2. **Activity Display Components**
   - Activity Type badges with icons and colors
   - Power association indicators
   - Activity Type descriptions

### State Management

- **Activity Authoring Provider** (`activity_authoring_provider.dart`)
  - Manages authored activities
  - Handles blockchain transactions
  - Filters by Activity Type and Power

### Blockchain Service

- **`createActivityScript`** method updated to include:
  - ActivityType enum parameter
  - Author ID
  - Decentralized storage reference
  - Enhanced metadata support

## Storage Structure

### On-Chain Storage
- Activity Type (enum)
- Primary Power (enum)
- Secondary Powers (enum array)
- Author ID
- Decentralized storage reference (IPFS hash)
- Basic metadata (JSON string)

### Off-Chain Storage (IPFS/Decentralized)
- Full activity content
- Tales and narrative content
- Rich media (images, videos)
- Extended metadata
- Activity history and stories

## Workflow

### Creating an Activity

1. User navigates to Activity Authoring Screen
2. Selects Activity Type (required)
3. Enters basic information (title, description, instructions)
4. Selects Primary Power (required)
5. Optionally selects up to 4 Secondary Powers
6. Configures activity settings (difficulty, duration, experience)
7. Adds optional metadata (Tales, narrative, tags)
8. Submits activity
9. Activity metadata uploaded to IPFS (if applicable)
10. Activity created on blockchain with IPFS hash reference
11. Activity saved to local state

### Viewing Activities

- Activities can be filtered by:
  - Activity Type
  - Power Type (primary or secondary)
  - Author
  - Difficulty
  - Status

## Universal Rule

**All Activity Types must be configurable to associate with one or more of the 5 Powers.** This association must be:
- ✅ Visible in the UI
- ✅ Included in the data schema
- ✅ Stored in decentralized storage
- ✅ Referenced via smart contracts for verification and progression

## Implementation Status

- ✅ Smart contract updated with ActivityType enum
- ✅ Data model updated with ActivityType and Power associations
- ✅ Activity Authoring UI screen created
- ✅ Activity Authoring Provider created
- ✅ Blockchain service updated with createActivityScript
- ✅ Constants updated with ActivityType colors and icons
- ⏳ IPFS integration for decentralized storage (pending)
- ⏳ Activity filtering UI components (pending)
- ⏳ Tales narrative editor (pending)

## Next Steps

1. Implement IPFS integration for decentralized storage
2. Create activity filtering and browsing UI
3. Add Tales narrative editor component
4. Implement activity discovery by Type and Power
5. Add activity templates for each Activity Type
6. Create activity authoring guidelines and best practices

## References

- Smart Contract: `contracts/ActivityScripts.sol`
- Data Model: `lib/models/activity_script.dart`
- UI Screen: `lib/screens/activity_authoring_screen.dart`
- Provider: `lib/providers/activity_authoring_provider.dart`
- Constants: `lib/constants/app_constants.dart`

