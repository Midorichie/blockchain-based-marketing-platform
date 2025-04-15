# Blockchain Marketing Campaign Platform

A decentralized platform for managing marketing campaigns using smart contracts on the Stacks blockchain.

## Overview

This platform enables advertisers to create marketing campaigns with automated budget allocation and performance-based rewards. The smart contracts ensure transparency and trust between advertisers and promoters.

## Architecture

The platform consists of two main components:

1. **Marketing Campaign Contract**: Manages campaign lifecycle, metrics, and rewards
2. **Ad Provider Contract**: Handles authentication and trust scoring for campaign metrics providers

## Key Features

- Create campaigns with STX budget escrow
- Manage authorized ad providers with trust scores
- Track campaign metrics (impressions, clicks, conversions)
- Automate reward distribution based on performance
- Time-based campaign expiration and fund recovery
- Security-focused role-based access control

## Setup & Installation

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Git

### Installation

1. Install Clarinet and Stacks CLI:
```bash
npm install -g @stacks/cli
npm install -g clarinet
```

2. Clone the repository:
```bash
git clone https://github.com/midorichie/marketing-campaign-platform.git
cd marketing-campaign-platform
```

3. Initialize the project:
```bash
clarinet integrate
```

## Smart Contract Structure

### Marketing Campaign Contract

Core contract that manages:
- Campaign creation and funding
- Performance metrics tracking
- Reward distribution
- Fund escrow and release

### Ad Provider Contract

Support contract that handles:
- Provider registration and management
- Trust scoring system
- Provider authentication

## Development

### Local Testing

Run the test suite:
```bash
clarinet test
```

### Deploying Contracts

Deploy to the testnet:
```bash
clarinet deploy --testnet
```

## Usage Examples

### Creating a Campaign

```clarity
(contract-call? .marketing-campaign create-campaign u1000 u10000 u500 u50 u10080)
```

Parameters:
- Budget (STX)
- Impression goal
- Click goal
- Conversion goal
- Duration (in blocks)

### Registering an Ad Provider

```clarity
(contract-call? .ad-provider register-provider 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM "Analytics Provider")
```

Parameters:
- Provider address
- Provider name

### Adding Provider to Campaign

```clarity
(contract-call? .marketing-campaign add-campaign-provider u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

Parameters:
- Campaign ID
- Provider address

### Updating Metrics

```clarity
(contract-call? .marketing-campaign update-metrics u1 u1000 u100 u10)
```

Parameters:
- Campaign ID
- Impressions
- Clicks
- Conversions

### Processing Rewards

```clarity
(contract-call? .marketing-campaign process-rewards u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

Parameters:
- Campaign ID
- Recipient address

## Security Features

- Role-based access control
- Secure STX handling with escrow
- Provider authentication and trust scoring
- Time-based security measures
- Input validation and error handling

## License

MIT
