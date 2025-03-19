// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/VincentTestHelper.sol";

/**
 * @title VincentUserFacetTest
 * @dev Tests for the VincentUserFacet and VincentUserViewFacet contracts
 */
contract VincentUserFacetTest is VincentTestHelper {
    // Test variables
    uint256 public appId;
    uint256 public appVersion;
    uint256 public pkpTokenId;

    // Events
    event AppVersionPermitted(uint256 indexed pkpTokenId, uint256 indexed appId, uint256 indexed appVersion);
    event AppVersionUnPermitted(uint256 indexed pkpTokenId, uint256 indexed appId, uint256 indexed appVersion);
    event ToolPolicyParameterSet(
        uint256 indexed pkpTokenId,
        uint256 indexed appId,
        uint256 indexed appVersion,
        bytes32 hashedToolIpfsCid,
        bytes32 hashedPolicyParameterName
    );
    event ToolPolicyParameterRemoved(
        uint256 indexed pkpTokenId,
        uint256 indexed appId,
        uint256 indexed appVersion,
        bytes32 hashedToolIpfsCid,
        bytes32 hashedPolicyParameterName
    );

    function setUp() public override {
        // Call parent setup
        super.setUp();

        // Set up the test as the deployer
        vm.startPrank(deployer);

        // Set up a PKP token for testing
        pkpTokenId = TEST_PKP_TOKEN_ID_1;

        // Register an app with a version for testing
        (appId, appVersion) = _registerTestAppWithVersion();
    }

    function testPermitAppVersion() public {
        // Create parameter arrays for permitAppVersion
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        // The permit function only emits ToolPolicyParameterSet events
        // We need to check for the hashedToolIpfsCid and hashedPolicyParameterName
        bytes32 hashedToolIpfsCid = keccak256(abi.encodePacked(TEST_TOOL_IPFS_CID_1));
        bytes32 hashedPolicyParameterName = keccak256(abi.encodePacked(TEST_POLICY_PARAM_1));

        // Expect the AppVersionPermitted event
        vm.expectEmit(true, true, true, true);
        emit AppVersionPermitted(pkpTokenId, appId, appVersion);

        // We now expect the ToolPolicyParameterSet event
        vm.expectEmit(true, true, true, false);
        emit ToolPolicyParameterSet(pkpTokenId, appId, appVersion, hashedToolIpfsCid, hashedPolicyParameterName);

        // Permit the app version
        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Verify the app version is permitted
        uint256[] memory permittedVersions = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId, appId);
        assertEq(permittedVersions.length, 1, "Should have 1 permitted version");
        assertEq(permittedVersions[0], appVersion, "Version should be permitted");

        // Check that the app ID is in the list of permitted apps
        uint256[] memory permittedAppIds = wrappedUserViewFacet.getAllPermittedAppIdsForPkp(pkpTokenId);
        assertEq(permittedAppIds.length, 1, "Should have 1 permitted app");
        assertEq(permittedAppIds[0], appId, "App should be permitted");

        // Verify agent PKP is registered
        uint256[] memory registeredPkps = wrappedUserViewFacet.getAllRegisteredAgentPkps();
        bool foundPkp = false;
        for (uint256 i = 0; i < registeredPkps.length; i++) {
            if (registeredPkps[i] == pkpTokenId) {
                foundPkp = true;
                break;
            }
        }
        assertTrue(foundPkp, "PKP should be registered as an agent");
    }

    function testUnPermitAppVersion() public {
        // First permit the app version
        // Create parameter arrays for permitAppVersion
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        // The permit function also emits ToolPolicyParameterSet events
        bytes32 hashedToolIpfsCid = keccak256(abi.encodePacked(TEST_TOOL_IPFS_CID_1));
        bytes32 hashedPolicyParameterName = keccak256(abi.encodePacked(TEST_POLICY_PARAM_1));

        // Permit the app version without expecting events (we're not testing this part)
        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Expect the AppVersionUnPermitted event
        vm.expectEmit(true, true, true, true);
        emit AppVersionUnPermitted(pkpTokenId, appId, appVersion);

        // Unpermit the app version
        wrappedUserFacet.unPermitAppVersion(pkpTokenId, appId, appVersion);

        // Verify the app version is no longer permitted
        uint256[] memory permittedVersions = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId, appId);
        assertEq(permittedVersions.length, 0, "Should have 0 permitted versions");

        // Check that the app ID is not in the list of permitted apps
        uint256[] memory permittedAppIds = wrappedUserViewFacet.getAllPermittedAppIdsForPkp(pkpTokenId);
        assertEq(permittedAppIds.length, 0, "Should have 0 permitted apps");
    }

    function testGetPermittedToolsForPkpAndAppVersion() public {
        // First permit the app version
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Get permitted tools
        string[] memory tools = wrappedUserViewFacet.getPermittedToolsForPkpAndAppVersion(pkpTokenId, appId, appVersion);

        // Verify we get the right tools
        assertEq(tools.length, 1, "Should have 1 tool");
        assertEq(tools[0], TEST_TOOL_IPFS_CID_1, "Tool should match");
    }

    function testSetAndGetToolPolicyParameters() public {
        // First permit the app version with no parameters
        string[] memory emptyTools = new string[](0);
        string[][] memory emptyPolicies = new string[][](0);
        string[][][] memory emptyParamNames = new string[][][](0);
        string[][][] memory emptyParamValues = new string[][][](0);

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, emptyTools, emptyPolicies, emptyParamNames, emptyParamValues
        );

        // Set up parameter arrays for setToolPolicyParameters
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        // Set up event expectations
        bytes32 hashedToolIpfsCid = keccak256(abi.encodePacked(TEST_TOOL_IPFS_CID_1));
        bytes32 hashedPolicyParameterName = keccak256(abi.encodePacked(TEST_POLICY_PARAM_1));
        vm.expectEmit(true, true, true, true);
        emit ToolPolicyParameterSet(pkpTokenId, appId, appVersion, hashedToolIpfsCid, hashedPolicyParameterName);

        // Set the parameters
        wrappedUserFacet.setToolPolicyParameters(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Get the policy parameters
        VincentUserViewFacet.PolicyWithParameters[] memory policies = wrappedUserViewFacet
            .getAllPoliciesWithParametersForTool(pkpTokenId, appId, appVersion, TEST_TOOL_IPFS_CID_1);

        // Verify we have the policy with parameters
        assertEq(policies.length, 1, "Should have 1 policy");
        assertEq(policies[0].policyIpfsCid, TEST_POLICY_1, "Policy should match");
        assertEq(policies[0].parameters.length, 1, "Should have 1 parameter");
        assertEq(policies[0].parameters[0].name, TEST_POLICY_PARAM_1, "Parameter name should match");
        assertEq(policies[0].parameters[0].value, "test-value", "Parameter value should match");
    }

    function testRemoveToolPolicyParameters() public {
        // First permit the app version with parameters
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Set up event expectations for removal
        bytes32 hashedToolIpfsCid = keccak256(abi.encodePacked(TEST_TOOL_IPFS_CID_1));
        bytes32 hashedPolicyParameterName = keccak256(abi.encodePacked(TEST_POLICY_PARAM_1));
        vm.expectEmit(true, true, true, true);
        emit ToolPolicyParameterRemoved(pkpTokenId, appId, appVersion, hashedToolIpfsCid, hashedPolicyParameterName);

        // Remove the parameters
        wrappedUserFacet.removeToolPolicyParameters(
            appId, pkpTokenId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames
        );

        // Get the policy parameters
        VincentUserViewFacet.PolicyWithParameters[] memory policies = wrappedUserViewFacet
            .getAllPoliciesWithParametersForTool(pkpTokenId, appId, appVersion, TEST_TOOL_IPFS_CID_1);

        // There should be no parameters left
        assertEq(policies.length, 0, "Should have 0 policies after removal");
    }

    function testIsToolPermittedForDelegateeAndPkp() public {
        // First permit the app version
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );

        // Check if the tool is permitted
        bool isPermitted =
            wrappedUserViewFacet.isToolPermittedForDelegateeAndPkp(TEST_DELEGATEE_1, pkpTokenId, TEST_TOOL_IPFS_CID_1);
        assertTrue(isPermitted, "Tool should be permitted for delegatee and PKP");

        // Try with a non-delegatee address (should revert)
        vm.expectRevert(
            abi.encodeWithSelector(VincentUserViewFacet.DelegateeNotAssociatedWithApp.selector, address(0x3))
        );
        wrappedUserViewFacet.isToolPermittedForDelegateeAndPkp(address(0x3), pkpTokenId, TEST_TOOL_IPFS_CID_1);

        // Try with a non-permitted app version
        wrappedUserFacet.unPermitAppVersion(pkpTokenId, appId, appVersion);
        isPermitted =
            wrappedUserViewFacet.isToolPermittedForDelegateeAndPkp(TEST_DELEGATEE_1, pkpTokenId, TEST_TOOL_IPFS_CID_1);
        assertFalse(isPermitted, "Tool should not be permitted after unpermitting app version");
    }

    function testFailGetPermittedToolsForNonPermittedPkp() public {
        // Try to get permitted tools for a PKP that doesn't have the app version permitted
        // This should revert with PkpNotPermittedForAppVersion
        wrappedUserViewFacet.getPermittedToolsForPkpAndAppVersion(pkpTokenId, appId, appVersion);
    }

    function testFailGetPolicyParametersForNonPermittedPkp() public {
        // Try to get policy parameters for a PKP that doesn't have the app version permitted
        // This should revert with PkpNotPermittedForAppVersion
        wrappedUserViewFacet.getAllPoliciesWithParametersForTool(pkpTokenId, appId, appVersion, TEST_TOOL_IPFS_CID_1);
    }

    function testFailSetParametersNonPkpOwner() public {
        // Try to set parameters as non-PKP owner (should revert)
        vm.stopPrank();
        vm.startPrank(nonOwner);

        // Set up parameter arrays
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        string[][][] memory policyParameterValues = new string[][][](1);
        policyParameterValues[0] = new string[][](1);
        policyParameterValues[0][0] = new string[](1);
        policyParameterValues[0][0][0] = "test-value";

        // This should revert with NotPkpOwner
        wrappedUserFacet.setToolPolicyParameters(
            pkpTokenId, appId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames, policyParameterValues
        );
    }

    function testFailRemoveParametersNonPkpOwner() public {
        // Try to remove parameters as non-PKP owner (should revert)
        vm.stopPrank();
        vm.startPrank(nonOwner);

        // Set up parameter arrays
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_1;

        string[][] memory policyIpfsCids = new string[][](1);
        policyIpfsCids[0] = new string[](1);
        policyIpfsCids[0][0] = TEST_POLICY_1;

        string[][][] memory policyParameterNames = new string[][][](1);
        policyParameterNames[0] = new string[][](1);
        policyParameterNames[0][0] = new string[](1);
        policyParameterNames[0][0][0] = TEST_POLICY_PARAM_1;

        // This should revert with NotPkpOwner
        wrappedUserFacet.removeToolPolicyParameters(
            appId, pkpTokenId, appVersion, toolIpfsCids, policyIpfsCids, policyParameterNames
        );
    }

    function testMultiplePermissions() public {
        // Register another app with a version
        string[] memory domains = new string[](1);
        domains[0] = TEST_DOMAIN_2;

        string[] memory redirectUris = new string[](1);
        redirectUris[0] = TEST_REDIRECT_URI_2;

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE_2;

        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_IPFS_CID_2;

        string[][] memory toolPolicies = new string[][](1);
        toolPolicies[0] = new string[](1);
        toolPolicies[0][0] = TEST_POLICY_2;

        string[][][] memory toolPolicyParameterNames = new string[][][](1);
        toolPolicyParameterNames[0] = new string[][](1);
        toolPolicyParameterNames[0][0] = new string[](1);
        toolPolicyParameterNames[0][0][0] = TEST_POLICY_PARAM_2;

        // Register tool first
        wrappedToolFacet.registerTool(TEST_TOOL_IPFS_CID_2);

        // Register the app
        uint256 appId2;
        uint256 appVersion2;
        (appId2, appVersion2) = wrappedAppFacet.registerAppWithVersion(
            "Test App 2",
            "Test App Description 2",
            domains,
            redirectUris,
            delegatees,
            toolIpfsCids,
            toolPolicies,
            toolPolicyParameterNames
        );

        // Permit both app versions
        string[] memory emptyTools = new string[](0);
        string[][] memory emptyPolicies = new string[][](0);
        string[][][] memory emptyParamNames = new string[][][](0);
        string[][][] memory emptyParamValues = new string[][][](0);

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, emptyTools, emptyPolicies, emptyParamNames, emptyParamValues
        );

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId2, appVersion2, emptyTools, emptyPolicies, emptyParamNames, emptyParamValues
        );

        // Verify both app IDs are permitted
        uint256[] memory permittedAppIds = wrappedUserViewFacet.getAllPermittedAppIdsForPkp(pkpTokenId);
        assertEq(permittedAppIds.length, 2, "Should have 2 permitted apps");

        // Check app IDs (order may vary)
        bool foundApp1 = false;
        bool foundApp2 = false;
        for (uint256 i = 0; i < permittedAppIds.length; i++) {
            if (permittedAppIds[i] == appId) {
                foundApp1 = true;
            } else if (permittedAppIds[i] == appId2) {
                foundApp2 = true;
            }
        }
        assertTrue(foundApp1, "App 1 should be permitted");
        assertTrue(foundApp2, "App 2 should be permitted");

        // Verify versions for app 1
        uint256[] memory permittedVersions1 = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId, appId);
        assertEq(permittedVersions1.length, 1, "Should have 1 permitted version for app 1");
        assertEq(permittedVersions1[0], appVersion, "Version should match for app 1");

        // Verify versions for app 2
        uint256[] memory permittedVersions2 = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId, appId2);
        assertEq(permittedVersions2.length, 1, "Should have 1 permitted version for app 2");
        assertEq(permittedVersions2[0], appVersion2, "Version should match for app 2");
    }

    // Helper function to test with a different PKP
    function testMultiplePkps() public {
        // Set up a second PKP token
        uint256 pkpTokenId2 = TEST_PKP_TOKEN_ID_2;
        mockPkpNft.setOwner(pkpTokenId2, deployer);

        // Permit app version for both PKPs
        string[] memory emptyTools = new string[](0);
        string[][] memory emptyPolicies = new string[][](0);
        string[][][] memory emptyParamNames = new string[][][](0);
        string[][][] memory emptyParamValues = new string[][][](0);

        wrappedUserFacet.permitAppVersion(
            pkpTokenId, appId, appVersion, emptyTools, emptyPolicies, emptyParamNames, emptyParamValues
        );

        wrappedUserFacet.permitAppVersion(
            pkpTokenId2, appId, appVersion, emptyTools, emptyPolicies, emptyParamNames, emptyParamValues
        );

        // Verify both PKPs are registered as agents
        uint256[] memory registeredPkps = wrappedUserViewFacet.getAllRegisteredAgentPkps();
        assertEq(registeredPkps.length, 2, "Should have 2 registered PKPs");

        // Check PKP IDs (order may vary)
        bool foundPkp1 = false;
        bool foundPkp2 = false;
        for (uint256 i = 0; i < registeredPkps.length; i++) {
            if (registeredPkps[i] == pkpTokenId) {
                foundPkp1 = true;
            } else if (registeredPkps[i] == pkpTokenId2) {
                foundPkp2 = true;
            }
        }
        assertTrue(foundPkp1, "PKP 1 should be registered");
        assertTrue(foundPkp2, "PKP 2 should be registered");

        // Verify app permissions for both PKPs
        uint256[] memory permittedVersions1 = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId, appId);
        uint256[] memory permittedVersions2 = wrappedUserViewFacet.getPermittedAppVersionsForPkp(pkpTokenId2, appId);

        assertEq(permittedVersions1.length, 1, "PKP 1 should have 1 permitted version");
        assertEq(permittedVersions2.length, 1, "PKP 2 should have 1 permitted version");
        assertEq(permittedVersions1[0], appVersion, "PKP 1 permitted version should match");
        assertEq(permittedVersions2[0], appVersion, "PKP 2 permitted version should match");
    }
}
