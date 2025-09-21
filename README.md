# zk-proof-of-burn

A minimal end-to-end scaffold for generating and verifying zero-knowledge proofs that an ETH burn took place. It contains:

- A Noir circuit that proves inclusion of a burn event in an off-chain Poseidon Merkle tree and exposes a unique nullifier.
- A Solidity manager contract that consumes the zk proof, tracks nullifiers, and records claimable balances.
- A TypeScript SDK that handles witness construction, proof generation, and contract interactions.
- Forge tests that exercise the contract logic with a mock verifier.

## Repository layout

```
├── circuits/proof_of_burn      # Noir circuit + Nargo project
├── sdk                         # TypeScript SDK for proof generation + contract helpers
├── src                         # Solidity contracts (manager, verifier interface, Ownable helper)
└── test                        # Forge tests & mock verifier
```

## Circuit overview

`circuits/proof_of_burn/src/main.nr` enforces the following statements:

- Public inputs: `burn_root`, `amount`, and the returned `nullifier` (in that order).
- Private witness: the claimer's address, transaction hash split into 2 field elements, timestamp, salt, amount, Merkle path, and index.
- The burn destination is fixed to the canonical address `0x000000000000000000000000000000000000dEaD`.
- The leaf commitment is `Poseidon(sender, burnAddress, txHashHi, txHashLo, amount, timestamp)` and must exist in the supplied Merkle tree with root `burn_root`.
- The nullifier is derived as `Poseidon(sender, txHashHi, txHashLo, salt)` ensuring one-time claims.

You can tweak `MERKLE_HEIGHT` if your commitment tree has a different depth.

### Compiling the circuit

```
cd circuits/proof_of_burn
nargo check                # sanity check your inputs
nargo compile              # generates proof_of_burn.acir and witness template
```

To obtain proving and verification keys (Groth16/Plonk) you can use `nargo prove` or `bb`/`snarkjs` depending on your proving stack. Once you have a `.zkey`, run `snarkjs zkey export solidityverifier` (Groth16) or the Noir `nargo codegen-verifier` command to produce a Solidity verifier that satisfies `IBurnVerifier`.

## Solidity contracts

- `src/ProofOfBurn.sol` stores the latest commitment root, references an external verifier, and marks nullifiers as spent while tallying balances per receiver.
- `src/interfaces/IBurnVerifier.sol` defines the verification contract surface expected on-chain.
- `src/utils/Ownable.sol` is a lightweight Ownable implementation used to protect admin operations.

Key flows:

1. The owner updates `burnRoot` whenever the watcher publishes a new Merkle root.
2. A claimer submits `{ proof, publicInputs }`, where `publicInputs == [burnRoot, amount, nullifier]` from the circuit, along with a receiver address.
3. The contract checks the root, verifies the zk proof, and records the nullifier so the claim cannot be replayed.

## SDK usage

Install dependencies inside `sdk/` (requires access to npm registries):

```
cd sdk
npm install
npm run build
```

Example proof generation and contract call encoding:

```ts
import { generateBurnProof, buildCircuitInputs, encodeProofForContract } from "./dist/index.js";

const artifacts = { acirPath: "../circuits/proof_of_burn/target/proof_of_burn.acir" };
const witness = {
  sender: "0x1234...",
  txHash: "0xdeadbeef...",
  timestamp: BigInt(1700000000),
  amount: 1_000000000000000000n,
  salt: 42n,
  merkle: { path: Array(32).fill(0n), leafIndex: 0 },
  burnRoot: 0x1234567890n,
};

const proof = await generateBurnProof(artifacts, witness);
const calldata = encodeProofForContract(proof);
// submit calldata.proof + calldata.publicInputs to the ProofOfBurn contract
```

`buildCircuitInputs` is exported in case you want to inspect the witness before generating proofs. The SDK expects Merkle path elements and the root as BN254 field elements (use Poseidon-compatible hashing in your indexer).

## Running tests

```
forge fmt
forge build
forge test
```

Tests use `MockBurnVerifier` to bypass heavy zk verification while still exercising state transitions, nullifier replay protection, and admin controls.

## Next steps

1. Generate a real verifier contract from the Noir circuit and replace the mock in deployment.
2. Wire an indexer that ingests on-chain burn events, builds the Poseidon Merkle tree, and pushes new roots to `setBurnRoot`.
3. Extend the manager to mint receipts, stream claims, or integrate with the intended application logic.
4. Harden the SDK with schema validation and integrate with your proof generation pipeline or a proving service.

