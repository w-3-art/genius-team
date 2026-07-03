# genius-dev-web3 — Reference Details

Loaded on demand from `SKILL.md`. Contains the full playbooks, patterns, and
checklists for the Web3 dev skill.

---

## Supported Stacks (full detail)

### EVM
- **Solidity 0.8.x** — default language, always latest stable
- **Vyper 0.3.x+** — when requested for security-first profile
- **Foundry** — preferred toolchain (forge test, cast call, anvil for local node)
- **Hardhat** — when the project already uses it
- **OpenZeppelin Contracts ≥5.0** — reference library for standards
- **viem + wagmi** — preferred client libs (ethers.js only if project already uses it)

### Non-EVM
- **Solana** — Anchor (Rust) for programs, `@solana/web3.js` + `@coral-xyz/anchor` for clients
- **Starknet** — Cairo 2.x, Starkli, `starknet.js`
- **Move (Sui/Aptos)** — Sui Move, Aptos Move, respective CLIs

Detect the stack by reading `foundry.toml` / `hardhat.config.ts` / `Anchor.toml`
/ `Scarb.toml` / `Move.toml` BEFORE writing any code.

---

## Workflow Protocol (full detail)

### Phase 0: Discover
Read, in this order:
1. `foundry.toml` / `hardhat.config.ts` / `Anchor.toml` — which stack?
2. `remappings.txt` / `package.json` — which libs (OpenZeppelin version?)
3. `src/` / `contracts/` — existing contracts to extend (inherit, don't duplicate)
4. `test/` — existing test patterns (match the style)
5. `.genius/web3/deployments.json` — already-deployed addresses
6. `.env` (`.env.example`) — which RPCs, which chain IDs

### Phase 1: Design
Before writing ANY contract code, produce a design note in `.genius/web3/design-{feature}.md`:
- **State variables** (types, visibility, gas layout — pack `uint128` pairs)
- **Functions** (external/public/internal/private, mutability, caller)
- **Events** (indexed args)
- **Errors** (custom errors)
- **Invariants** (what must always be true)
- **Upgrade path** (immutable? UUPS? Transparent?)
- **Access matrix** (who can call what)

### Phase 2: Implement
1. Contract in `src/` (Foundry) or `contracts/` (Hardhat)
2. Import OpenZeppelin for standards — never re-implement ERC-20/721/1155/4626
3. Every function has NatSpec (`@notice`, `@param`, `@return`, `@dev`)
4. Every storage var has a comment explaining its role
5. Apply the 10 security rules from SKILL.md

### Phase 3: Test
```bash
forge fmt
forge build
forge test -vv
forge test --fuzz-runs 10000 --match-test testFuzz
forge coverage --report summary   # aim 100% on state-changing code
forge snapshot
```
If Hardhat: `pnpm hardhat test`, `pnpm hardhat coverage`.
If Anchor: `anchor test`.

### Phase 4: Static Analysis
```bash
slither . --print human-summary                  # quick triage
slither . --checklist --markdown-root src/       # full report
aderyn                                           # Rust-based complement
```
Triage every High/Medium finding. Suppress Lows only with a written justification in the PR.

### Phase 5: Deploy (testnet first)
```bash
# Dry run
forge script script/Deploy.s.sol --rpc-url $RPC_TESTNET

# Broadcast
forge script script/Deploy.s.sol --rpc-url $RPC_TESTNET \
  --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

# Record
jq --arg addr "$ADDR" --arg chain "$CHAIN" --arg tx "$TX" \
  '.deployments += [{"contract": "Foo", "address": $addr, "chain": $chain, "tx": $tx, "timestamp": now}]' \
  .genius/web3/deployments.json > /tmp/d.json && mv /tmp/d.json .genius/web3/deployments.json
```

### Phase 6: Frontend Wiring (if dApp)
- Use `viem` for reads, `wagmi` hooks for React
- `useReadContract`, `useWriteContract`, `useWaitForTransactionReceipt`
- Always show tx hash + block explorer link to user
- Always handle `UserRejectedRequestError`
- Always display chain mismatch warnings (wrong network)

---

## Test Coverage Minimums

- **Happy path**: every external function
- **Revert path**: every `require`/`revert`/custom error must have a test that triggers it
- **Fuzz**: any function with arithmetic or boundary logic gets at least one `forge test --fuzz-runs 10000`
- **Invariants**: for stateful contracts, write at least one Foundry invariant test
- **Gas snapshot**: `forge snapshot` before/after every PR

## Deployment Discipline

- **Never deploy to mainnet without testnet parity run**
- Use `forge script` with `--broadcast` only after a dry-run
- Commit deployed addresses to `.genius/web3/deployments.json`
- **Verify** contracts on Etherscan/Blockscout IMMEDIATELY after deploy (`forge verify-contract`)
- Transfer ownership to a multisig (Safe) before any mainnet TVL grows

---

## Gas Optimization Playbook

Before claiming "gas-optimized":
1. Pack storage slots (uint128 + uint128, bool + address, ...)
2. Use `calldata` instead of `memory` for external function args
3. Prefer `++i` over `i++` in loops (saves 5 gas per iteration)
4. Cache storage reads in loops — never re-read a state var inside a loop
5. Use custom errors (~50 gas cheaper than require strings)
6. Use `immutable` for constructor-set vars that never change
7. Use `constant` for literal values
8. Unchecked blocks for loop counters that cannot overflow
9. Prefer bit flags over multiple bool variables
10. Short-circuit expensive checks (order require statements cheapest-first)

Run `forge snapshot --diff` to PROVE gas savings — never claim without numbers.

---

## Common Contract Patterns

### Token (ERC-20)
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
contract MyToken is ERC20, Ownable2Step {
    error MaxSupplyExceeded();
    uint256 public immutable MAX_SUPPLY;
    constructor(uint256 maxSupply_) ERC20("MyToken", "MTK") Ownable(msg.sender) {
        MAX_SUPPLY = maxSupply_;
    }
    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(to, amount);
    }
}
```

### NFT (ERC-721 with royalties)
Use `ERC721Royalty` from OZ; always implement `supportsInterface`; lazy-mint via signatures if mint cost matters.

### Vault (ERC-4626)
Use `ERC4626` from OZ; read the OZ docs on inflation attacks; always initialize with a dead-shares mint.

### Staking
Use `cumulativeRewardPerShare` pattern (Sushi masterchef style); never a loop over stakers.

### Vesting / Airdrop
Prefer merkle airdrops over iteration; use `MerkleProof.verify` from OZ.

---

## Memory Integration (full detail)

### On Implementation Start
Read `.genius/memory/BRIEFING.md` for project context (chain, protocol domain, past audit findings).
Read `.genius/web3/deployments.json` for already-live addresses.

### On Decision Made
Append to `.genius/memory/decisions.json` — include chain ID, gas estimate, security trade-offs.

### On Security Finding
Append to `.genius/memory/errors.json` with severity (Critical/High/Medium/Low) — these compound over a project.

### On Contract Deployed
Append to `.genius/web3/deployments.json` — address, tx, chain, constructor args, verified status.

---

## Definition of Done (full checklist)

Web3 implementation is DONE only when ALL of:
- [ ] `forge build` green with 0 warnings
- [ ] `forge test` green, coverage ≥95% on state-changing code
- [ ] `forge test --fuzz-runs 10000` green on math-heavy functions
- [ ] Invariant tests written for stateful contracts
- [ ] Slither + Aderyn clean (or every finding triaged in writing)
- [ ] NatSpec on every external/public function
- [ ] Gas snapshot committed (`.gas-snapshot` file)
- [ ] Testnet deployment successful + contract verified on block explorer
- [ ] Deployment metadata in `.genius/web3/deployments.json`
- [ ] No `tx.origin`, no bare `transfer()`, no unchecked external calls
- [ ] Ownership transferred to multisig (for mainnet deploys)
- [ ] `.env.example` updated with any new RPC/key var
- [ ] README updated with contract addresses + upgrade path notes

---

## Playground Update (MANDATORY)

After completing your task:
1. Update `.genius/DASHBOARD.html` — Web3 tab shows: deployed contracts,
   test coverage %, gas snapshot diff vs last run, Slither findings triaged
2. Link every contract address to its block explorer
3. Tell the user: `📊 Dashboard updated → open .genius/DASHBOARD.html`

---

## Escape Hatches

If a requirement CANNOT be satisfied securely (e.g. upgradable contract with
admin keys held by an EOA), STOP and raise the concern to the Lead with:
- The exact risk (what attacker can do)
- The mitigation options (multisig, timelock, renounce)
- The trade-off (UX vs safety)

Never ship a contract you would not audit yourself.
