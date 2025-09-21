// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ProofOfBurn} from "../src/ProofOfBurn.sol";
import {Ownable} from "../src/utils/Ownable.sol";
import {MockBurnVerifier} from "./mocks/MockBurnVerifier.sol";

contract ProofOfBurnTest is Test {
    ProofOfBurn internal manager;
    MockBurnVerifier internal verifier;

    uint256 internal constant DEFAULT_ROOT = uint256(0x1234);
    uint256 internal constant TEST_AMOUNT = 1 ether;
    uint256 internal constant TEST_NULLIFIER = uint256(0xabcde);

    address internal constant RECEIVER = address(0xBEEF);

    function setUp() public {
        verifier = new MockBurnVerifier();
        manager = new ProofOfBurn(DEFAULT_ROOT, verifier);
    }

    function _buildProofData(uint256 root, uint256 amount, uint256 nullifier)
        internal
        pure
        returns (ProofOfBurn.ProofData memory)
    {
        uint256[3] memory inputs = [root, amount, nullifier];
        return ProofOfBurn.ProofData({proof: hex"1234", publicInputs: inputs});
    }

    function testSubmitProofSucceeds() public {
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT, TEST_AMOUNT, TEST_NULLIFIER);
        verifier.setExpectedInputs(proofData.publicInputs, true);

        uint256 claimedAmount = manager.submitProof(proofData, RECEIVER);
        assertEq(claimedAmount, TEST_AMOUNT);
        assertEq(manager.claimedBy(RECEIVER), TEST_AMOUNT);
        assertTrue(manager.nullifierUsed(TEST_NULLIFIER));
    }

    function testSubmitProofRevertsWhenVerifierRejects() public {
        verifier.setShouldVerify(false);
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT, TEST_AMOUNT, TEST_NULLIFIER);

        vm.expectRevert(ProofOfBurn.InvalidProof.selector);
        manager.submitProof(proofData, RECEIVER);
    }

    function testSubmitProofRevertsOnNullifierReuse() public {
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT, TEST_AMOUNT, TEST_NULLIFIER);
        manager.submitProof(proofData, RECEIVER);

        vm.expectRevert(ProofOfBurn.NullifierAlreadyUsed.selector);
        manager.submitProof(proofData, RECEIVER);
    }

    function testSubmitProofRevertsOnRootMismatch() public {
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT + 1, TEST_AMOUNT, TEST_NULLIFIER);

        vm.expectRevert(ProofOfBurn.RootMismatch.selector);
        manager.submitProof(proofData, RECEIVER);
    }

    function testSubmitProofRevertsForZeroReceiver() public {
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT, TEST_AMOUNT, TEST_NULLIFIER);

        vm.expectRevert(ProofOfBurn.ZeroReceiver.selector);
        manager.submitProof(proofData, address(0));
    }

    function testSubmitProofRevertsForZeroAmount() public {
        ProofOfBurn.ProofData memory proofData = _buildProofData(DEFAULT_ROOT, 0, TEST_NULLIFIER);

        vm.expectRevert(ProofOfBurn.ZeroAmount.selector);
        manager.submitProof(proofData, RECEIVER);
    }

    function testOwnerCanUpdateRoot() public {
        uint256 newRoot = uint256(0xBEEF);
        manager.setBurnRoot(newRoot);
        assertEq(manager.burnRoot(), newRoot);
    }

    function testOwnerCanUpdateVerifier() public {
        MockBurnVerifier newVerifier = new MockBurnVerifier();
        manager.setVerifier(newVerifier);
        assertEq(address(manager.verifier()), address(newVerifier));
    }

    function testNonOwnerCannotUpdateRoot() public {
        vm.prank(address(0x123));
        vm.expectRevert(Ownable.NotOwner.selector);
        manager.setBurnRoot(uint256(0x999));
    }
}
