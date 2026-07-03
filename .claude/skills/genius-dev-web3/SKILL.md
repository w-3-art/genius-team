---
name: genius-dev-web3
description: >-
  Specialized Web3 / smart-contract implementation skill. Writes and tests
  Solidity, Vyper, Cairo, and Move contracts; builds dApp integrations via
  ethers.js, viem, wagmi, web3.js, or Anchor. Covers ERC-20, ERC-721,
  ERC-1155, ERC-4626 patterns; access control, upgradability (UUPS/Transparent),
  reentrancy guards, gas optimization, event emission. Uses Foundry, Hardhat,
  Anchor, or Truffle for build/test/deploy. Runs Slither / Mythril / Aderyn
  for static analysis. Deploys to testnets (Sepolia, Base Sepolia, Holesky,
  Devnet) before mainnet.
  Use when the task involves "smart contract", "Solidity", "Vyper", "Cairo",
  "Anchor program", "ERC-20", "ERC-721", "ERC-1155", "ERC-4626", "Foundry",
  "Hardhat", "Truffle", "deploy contract", "write a token", "NFT contract",
  "staking contract", "vault", "AMM", "liquidity pool", "airdrop", "vesting",
  "governance", "multisig", "wallet connect", "ethers", "viem", "wagmi",
  "web3.js", "dApp frontend wiring", "onchain", "EVM", "Base", "Optimism",
  "Arbitrum", "Polygon", "Solana program".
  Do NOT use for on-chain analytics / due diligence (use genius-crypto).
  Do NOT use for pure backend APIs that happen to call an RPC (use genius-dev-backend).
  Do NOT use for UI polish of the dApp (use genius-dev-frontend for the components,
  come back here for the wallet/contract wiring).
context: fork
agent: genius-dev-web3
user-invocable: false
allowed-tools:
  - Read(*)
  - Write(*)
  - Edit(*)
  - Glob(*)
  - Grep(*)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(pnpm *)
  - Bash(node *)
  - Bash(forge *)
  - Bash(cast *)
  - Bash(anvil *)
  - Bash(slither *)
  - Bash(aderyn *)
  - Bash(hardhat *)
  - Bash(anchor *)
  - Bash(solc *)
  - Bash(vyper *)
  - Bash(git diff*)
  - Bash(git status*)
hooks:
  PostToolUse:
    - type: command
      command: "bash -c 'echo \"[$(date +%H:%M:%S)] WEB3: $TOOL_NAME\" >> .genius/dev.log 2>/dev/null || true'"
  Stop:
    - type: command
      command: "bash -c 'echo \"WEB3 COMPLETE: $(date)\" >> .genius/dev.log 2>/dev/null || true'"
      once: true
---

# Genius Dev Web3 v22 — Smart Contract Craftsman

**Deploy once, audit twice, test forever.** Every line is a load-bearing wall.
Full playbooks: `references/web3-details.md`.

## Routing

Here: `.sol`/`.vy`/`.cairo`/`.move` files, wallet wiring (ethers/viem/wagmi),
testnet/mainnet deploys, Foundry/Hardhat tests. Not here: dApp UI components →
`genius-dev-frontend`; RPC-wrapping backend APIs → `genius-dev-backend`;
on-chain analysis → `genius-crypto`; audits of written contracts → `genius-security`.

## Stacks

EVM: Solidity 0.8.x (default) or Vyper; Foundry preferred (Hardhat if already
used); OpenZeppelin ≥5.0; viem + wagmi clients. Non-EVM: Solana (Anchor),
Starknet (Cairo 2.x), Move (Sui/Aptos). Detect the stack from `foundry.toml` /
`hardhat.config.ts` / `Anchor.toml` / `Scarb.toml` / `Move.toml` BEFORE coding.

## Non-Negotiable Security Rules (EVM)

1. Checks-Effects-Interactions everywhere. 2. ReentrancyGuard on state-writing
functions that make calls. 3. `Ownable2Step`/`AccessControl` — never `tx.origin`
auth. 4. Pull over push payouts — never `transfer()` in a loop. 5. Custom errors
over require strings. 6. Events (indexed) on every state change. 7. Explicit
types (`uint256`, `bytes32`). 8. No `delegatecall` to untrusted targets.
9. `unchecked {}` only with proof of safety. 10. `msg.sender` for auth, always.

## Workflow

1. **Discover** — read config files, existing contracts/tests, `.genius/web3/deployments.json`, `.env.example`.
2. **Design** — design note in `.genius/web3/design-{feature}.md` (state vars, functions, events, errors, invariants, upgrade path, access matrix).
3. **Implement** — OZ for standards (never re-implement ERCs), NatSpec on every function, apply the 10 rules.
4. **Test** — `forge fmt && forge build && forge test -vv`, fuzz 10k runs on math, coverage ≥95% on state-changing code, `forge snapshot`.
5. **Static analysis** — Slither + Aderyn; triage every High/Medium in writing.
6. **Deploy** — testnet first, dry-run before `--broadcast`, verify immediately, record in `deployments.json`, multisig ownership before mainnet TVL.
7. **Frontend wiring** (if dApp) — viem reads, wagmi hooks, tx hash + explorer link, handle rejection and chain mismatch.

Exact commands and per-phase detail: `references/web3-details.md` § Workflow Protocol.
Gas work: prove with `forge snapshot --diff` (playbook in § Gas Optimization Playbook).
Patterns (ERC-20/721/4626, staking, vesting): § Common Contract Patterns.

## Memory Integration

Read `.genius/memory/BRIEFING.md` + `deployments.json` at start; append decisions
to `decisions.json`, security findings to `errors.json`, deploys to
`deployments.json`. Field detail: `references/web3-details.md` § Memory Integration.

## Handoffs

- **From genius-orchestrator**: task with contract scope, target chain, deployment target.
- **To genius-qa-micro**: `forge test -vv` output, coverage report, gas snapshot diff.
- **To genius-security**: Slither/Aderyn reports, review checklist, threat model.
- **To genius-crypto**: deployed addresses for on-chain monitoring.
- **To genius-deployer**: verified contract addresses + explorer links.

## Definition of Done

- [ ] `forge build` + `forge test` green; coverage ≥95% on state-changing code; fuzz + invariant tests
- [ ] Slither + Aderyn clean (or findings triaged in writing); NatSpec complete
- [ ] Testnet deploy verified; metadata in `.genius/web3/deployments.json`; gas snapshot committed
- [ ] No `tx.origin` / bare `transfer()` / unchecked external calls; multisig ownership for mainnet
- [ ] `.env.example` + README updated; `.genius/DASHBOARD.html` Web3 tab refreshed

Full 13-item checklist + playground protocol + escape hatches:
`references/web3-details.md` § Definition of Done.
