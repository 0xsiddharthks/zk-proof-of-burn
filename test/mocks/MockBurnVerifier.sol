// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBurnVerifier} from "../../src/interfaces/IBurnVerifier.sol";

contract MockBurnVerifier is IBurnVerifier {
    bool public shouldVerify = true;
    bool public enforceMatch;
    uint256[3] public expectedInputs;

    function setShouldVerify(bool value) external {
        shouldVerify = value;
    }

    function setExpectedInputs(uint256[3] calldata inputs, bool enforce) external {
        expectedInputs = inputs;
        enforceMatch = enforce;
    }

    function verifyProof(bytes calldata, uint256[3] calldata publicInputs) external view override returns (bool) {
        if (enforceMatch) {
            for (uint256 i = 0; i < publicInputs.length; ++i) {
                if (publicInputs[i] != expectedInputs[i]) {
                    return false;
                }
            }
        }

        return shouldVerify;
    }
}
