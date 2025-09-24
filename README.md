# Invoice Factoring Platform

A decentralized platform for small businesses to sell their outstanding invoices to investors for immediate cash flow, built on the Stacks blockchain using Clarity smart contracts.

## Overview

The Invoice Factoring Platform enables small businesses to convert their accounts receivable into immediate cash by selling their outstanding invoices to investors at a discount. This creates a win-win situation where businesses get instant liquidity and investors earn returns when the invoices are paid.

## System Architecture

### Core Components

1. **Invoice Management**: Submit, verify, and track invoices through their lifecycle
2. **Buyer Verification**: Automated verification of invoice buyers and creditworthiness
3. **Payment Processing**: Secure handling of factoring transactions and settlements
4. **Automated Settlement**: Smart contract-based payment distribution upon invoice payment

### Key Features

- **Instant Liquidity**: Convert outstanding invoices to immediate cash
- **Automated Verification**: Built-in buyer verification and risk assessment
- **Transparent Pricing**: Market-driven discount rates for invoice factoring
- **Secure Settlement**: Automated payment processing upon invoice completion
- **Decentralized Trust**: Blockchain-based transparency and immutable records

## Smart Contracts

### invoice-factoring.clar

The main contract that handles:
- Invoice submission and validation
- Buyer verification processes  
- Factoring rate calculations
- Payment processing and escrow
- Settlement automation
- Dispute resolution mechanisms

## Technology Stack

- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Smart Contracts**: Clarity
- **Development**: Clarinet
- **Testing**: Clarinet + Vitest

## Getting Started

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet)
- [Node.js](https://nodejs.org/) (v16+)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/je344816/invoice-factoring-platform.git
   cd invoice-factoring-platform
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run contract checks:
   ```bash
   clarinet check
   ```

4. Run tests:
   ```bash
   npm test
   ```

## Usage

### For Businesses (Invoice Sellers)

1. **Submit Invoice**: Upload invoice details including amount, due date, and buyer information
2. **Verification**: System verifies invoice authenticity and buyer creditworthiness  
3. **Receive Offers**: Investors submit factoring offers with discount rates
4. **Accept Offer**: Choose the best factoring rate and receive immediate payment
5. **Settlement**: Upon invoice payment, remaining amount is automatically distributed

### For Investors (Invoice Buyers)

1. **Browse Invoices**: Review available invoices with risk assessments
2. **Submit Offers**: Propose factoring rates based on risk evaluation
3. **Purchase Invoice**: Upon acceptance, transfer funds to escrow
4. **Collect Payment**: Receive full invoice amount upon customer payment

## Contract Functions

### Public Functions

- `submit-invoice`: Submit a new invoice for factoring
- `verify-buyer`: Verify the creditworthiness of invoice buyers
- `submit-factoring-offer`: Submit an offer to purchase an invoice
- `accept-factoring-offer`: Accept a factoring offer for an invoice
- `mark-invoice-paid`: Mark an invoice as paid to trigger settlement
- `withdraw-funds`: Withdraw available funds from the contract

### Read-only Functions

- `get-invoice-details`: Retrieve details of a specific invoice
- `get-factoring-offers`: Get all offers for an invoice
- `get-user-balance`: Check user's balance in the contract
- `calculate-factoring-amount`: Calculate the amount after factoring discount

## Security Features

- **Multi-signature Support**: Enhanced security for large transactions
- **Time-locked Escrow**: Automatic refunds if settlement conditions aren't met
- **Dispute Resolution**: Built-in mechanisms for handling payment disputes
- **Risk Assessment**: Automated buyer verification and credit scoring

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
# Check contract syntax
clarinet check

# Run unit tests
npm test

# Run integration tests
npm run test:integration
```

## Deployment

### Testnet Deployment

```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue in this repository
- Contact the development team
- Review the documentation at [docs link]

## Roadmap

- [ ] Enhanced buyer verification algorithms
- [ ] Integration with traditional banking systems
- [ ] Mobile application development  
- [ ] Advanced analytics and reporting
- [ ] Cross-chain compatibility
- [ ] Institutional investor onboarding

---

Built with ❤️ using Stacks and Clarity smart contracts.