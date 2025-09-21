// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBurnVerifier {
    /// @notice Verifies a Groth16/Plonk proof for the proof-of-burn circuit.
    /// @param proof Serialized zk proof bytes.
    /// @param publicInputs Public inputs array ordered as [burnRoot, amount, nullifier].
    /// @return result True if the proof is valid.
    function verifyProof(bytes calldata proof, uint256[3] calldata publicInputs) external view returns (bool result);
}
