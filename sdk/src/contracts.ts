import { Contract, InterfaceAbi, Provider, Signer, hexlify, toBeHex } from "ethers";
import { BurnProof } from "./types";

export const PROOF_OF_BURN_ABI: InterfaceAbi = [
  {
    inputs: [
      {
        components: [
          { internalType: "bytes", name: "proof", type: "bytes" },
          { internalType: "uint256[3]", name: "publicInputs", type: "uint256[3]" },
        ],
        internalType: "struct ProofOfBurn.ProofData",
        name: "proofData",
        type: "tuple",
      },
      { internalType: "address", name: "receiver", type: "address" },
    ],
    name: "submitProof",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "burnRoot",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    name: "nullifierUsed",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "claimedBy",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];

type ContractRunner = Provider | Signer;

export function getProofOfBurnContract(address: string, runner: ContractRunner) {
  return new Contract(address, PROOF_OF_BURN_ABI, runner);
}

export function encodeProofForContract(proof: BurnProof) {
  const proofHex = hexlify(proof.proof);
  const publicInputsHex = proof.publicInputs.map((value) => toBeHex(value, 32));
  return { proof: proofHex, publicInputs: publicInputsHex };
}
