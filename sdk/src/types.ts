export interface MerkleProofInput {
  path: bigint[];
  leafIndex: number;
}

export interface BurnWitnessInput {
  sender: string; // 0x-prefixed address
  txHash: string; // 0x-prefixed transaction hash
  timestamp: number | bigint;
  amount: bigint;
  salt: bigint;
  merkle: MerkleProofInput;
  burnRoot: bigint;
}

export interface BurnProof {
  proof: Uint8Array;
  publicInputs: bigint[]; // [burn_root, amount, nullifier]
}

export interface CircuitArtifacts {
  acirPath: string;
  abiPath?: string;
}
