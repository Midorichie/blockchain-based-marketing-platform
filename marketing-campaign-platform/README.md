# Blockchain Marketing Campaign Platform

A decentralized platform for managing marketing campaigns using smart contracts on the Stacks blockchain.

## Overview

This platform enables advertisers to create marketing campaigns with automated budget allocation and performance-based rewards. The smart contracts ensure transparency and trust between advertisers and promoters.

## Features

- Create campaigns with predefined budgets and performance benchmarks
- Track campaign metrics (impressions, clicks, conversions)
- Automate reward distribution based on performance

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

The platform consists of the following smart contracts:

- `marketing-campaign.clar`: Core contract for campaign management

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

## Usage

### Creating a Campaign

```clarity
(contract-call? .marketing-campaign create-campaign u1000 u10000 u500 u50)
```

Parameters:
- Budget (STX)
- Impression goal
- Click goal
- Conversion goal

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
(contract-call? .marketing-campaign process-rewards u1)
```

Parameters:
- Campaign ID

## License

MIT
