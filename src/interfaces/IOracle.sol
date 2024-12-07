// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOracle {
    function requestResult(bytes32 marketId, string calldata eventId) external;
    function getResult(bytes32 marketId) external view returns (uint8, bool);
}
