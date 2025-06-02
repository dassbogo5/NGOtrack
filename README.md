
# 🌍 NGOtrack: Verified NGO Registry

A decentralized registry for verifying NGO legitimacy on the Stacks blockchain.

## 🎯 Features

- NGO registration with essential details
- Verification by contract owner
- Status management (pending/verified/rejected/suspended)
- Public verification checks
- Address-based NGO lookups

## 📚 Contract Functions

### Public Functions

- `register-ngo`: Register a new NGO
- `verify-ngo`: Verify an NGO (owner only)
- `update-ngo-status`: Update NGO status (owner only)

### Read-Only Functions

- `get-ngo-details`: Get NGO information
- `get-ngo-by-address`: Look up NGO by address
- `is-verified`: Check if NGO is verified

## 🚀 Getting Started

1. Clone the repository
2. Install Clarinet: `curl -L https://clarity.tools/install | sh`
3. Run tests: `clarinet test`

## 📋 Usage Examples

```clarity
;; Register an NGO
(contract-call? .ngotrack register-ngo "Red Cross" "RC123" "USA" u1960 "www.redcross.org" "contact@redcross.org")

;; Verify an NGO
(contract-call? .ngotrack verify-ngo u1)

;; Check NGO status
(contract-call? .ngotrack get-ngo-details u1)
```

## 🔒 Security

- Only contract owner can verify NGOs
- One address can register only one NGO
- Immutable registration data
- Status changes are tracked

## 👥 Contributing

PRs welcome! Please read our contributing guidelines first.

## 📜 License

MIT
```

Git commit message:
```
feat: Implement NGOtrack smart contract for on-chain NGO verification 🌍
```

PR Title:
```
NGOtrack: MVP Implementation for Verified NGO Registry
```

PR Description:
```
## 🎯 Changes Introduced

- Implemented core NGO registration system
- Added verification mechanism for contract owner
- Created status management system
- Implemented public verification checks
- Added address-based NGO lookups

## 🔍 Testing

- All tests passing
- Manually verified on local devnet
- Gas optimization performed

