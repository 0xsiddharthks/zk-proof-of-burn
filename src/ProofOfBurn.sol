// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBurnVerifier} from "./interfaces/IBurnVerifier.sol";
import {Ownable} from "./utils/Ownable.sol";

/// @title ProofOfBurn
/// @notice Accepts zero-knowledge proofs that attest ETH was burned off-chain and tracks the corresponding claims.
contract ProofOfBurn is Ownable {
    struct ProofData {
        bytes proof;
        uint256[3] publicInputs; // [burnRoot, amount, nullifier]
    }

    error InvalidProof();
    error NullifierAlreadyUsed();
    error RootMismatch();
    error ZeroVerifier();
    error ZeroReceiver();
    error ZeroAmount();

    event VerifierUpdated(address indexed newVerifier);
    event BurnRootUpdated(uint256 indexed newRoot);
    event BurnClaimed(address indexed caller, address indexed receiver, uint256 amount, uint256 nullifier);

    IBurnVerifier public verifier;
    uint256 public burnRoot;
    mapping(uint256 => bool) public nullifierUsed;
    mapping(address => uint256) public claimedBy;

    constructor(uint256 initialRoot, IBurnVerifier verifier_) Ownable(msg.sender) {
        if (address(verifier_) == address(0)) revert ZeroVerifier();
        verifier = verifier_;
        burnRoot = initialRoot;

        emit VerifierUpdated(address(verifier_));
        emit BurnRootUpdated(initialRoot);
    }

    function setVerifier(IBurnVerifier newVerifier) external onlyOwner {
        if (address(newVerifier) == address(0)) revert ZeroVerifier();
        verifier = newVerifier;
        emit VerifierUpdated(address(newVerifier));
    }

    function setBurnRoot(uint256 newRoot) external onlyOwner {
        burnRoot = newRoot;
        emit BurnRootUpdated(newRoot);
    }

    function submitProof(ProofData calldata proofData, address receiver) external returns (uint256 amount) {
        if (receiver == address(0)) revert ZeroReceiver();
        if (proofData.publicInputs[0] != burnRoot) revert RootMismatch();

        amount = proofData.publicInputs[1];
        if (amount == 0) revert ZeroAmount();

        uint256 nullifier = proofData.publicInputs[2];
        if (nullifierUsed[nullifier]) revert NullifierAlreadyUsed();

        bool verified = verifier.verifyProof(proofData.proof, proofData.publicInputs);
        if (!verified) revert InvalidProof();

        nullifierUsed[nullifier] = true;
        claimedBy[receiver] += amount;

        emit BurnClaimed(msg.sender, receiver, amount, nullifier);
    }
}
