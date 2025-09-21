import fs from "fs";
import path from "path";
import { Noir } from "@noir-lang/noir_js";
import { BarretenbergBackend } from "@noir-lang/barretenberg";
import { getAddress } from "ethers";
import { BurnWitnessInput, BurnProof, CircuitArtifacts } from "./types";

const FIELD_MASK_128 = (1n << 128n) - 1n;
const MERKLE_HEIGHT = 32;

function hexToBigInt(value: string): bigint {
  return BigInt(value);
}

function normaliseAddress(address: string): bigint {
  return hexToBigInt(getAddress(address));
}

function splitHash(value: string): { hi: bigint; lo: bigint } {
  const asBigInt = hexToBigInt(value);
  const lo = asBigInt & FIELD_MASK_128;
  const hi = asBigInt >> 128n;
  return { hi, lo };
}

function padMerklePath(pathValues: bigint[]): bigint[] {
  if (pathValues.length > MERKLE_HEIGHT) {
    throw new Error(`Merkle path longer than ${MERKLE_HEIGHT}`);
  }

  const padded = [...pathValues];
  while (padded.length < MERKLE_HEIGHT) {
    padded.push(0n);
  }

  return padded;
}

export function buildCircuitInputs(witness: BurnWitnessInput) {
  const senderField = normaliseAddress(witness.sender);
  const { hi: txHashHi, lo: txHashLo } = splitHash(witness.txHash);
  const timestamp = BigInt(witness.timestamp);
  const merklePath = padMerklePath(witness.merkle.path);

  return {
    burn_root: witness.burnRoot.toString(),
    amount: witness.amount.toString(),
    leaf_index: witness.merkle.leafIndex,
    merkle_path: merklePath.map((value) => value.toString()),
    sender: senderField.toString(),
    tx_hash_hi: txHashHi.toString(),
    tx_hash_lo: txHashLo.toString(),
    timestamp: timestamp.toString(),
    salt: witness.salt.toString(),
    amount_private: witness.amount.toString(),
  };
}

function resolveCircuitPath(filePath: string): Uint8Array {
  const absolute = path.resolve(filePath);
  const buffer = fs.readFileSync(absolute);
  return new Uint8Array(buffer);
}

export async function generateBurnProof(
  artifacts: CircuitArtifacts,
  witness: BurnWitnessInput,
): Promise<BurnProof> {
  const acir = resolveCircuitPath(artifacts.acirPath);
  const backend = await BarretenbergBackend.new(acir);
  const noir = new Noir(acir, backend);

  const circuitInputs = buildCircuitInputs(witness);
  const { proof, publicInputs } = await noir.generateProof(circuitInputs);

  await backend.destroy();

  return {
    proof,
    publicInputs: publicInputs.map((value: string | bigint) => BigInt(value)),
  };
}
