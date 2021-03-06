// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

interface IERC20 {
    // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

library SafeMath {
    // arithmetic wrapper for unit under/overflow check
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

interface IMOLOCH {
    // brief interface for moloch dao v2

    function depositToken() external view returns (address);

    function tokenWhitelist(address token) external view returns (bool);

    function getProposalFlags(uint256 proposalId)
        external
        view
        returns (bool[6] memory);

    function members(address user)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        );

    function userTokenBalances(address user, address token)
        external
        view
        returns (uint256);

    function cancelProposal(uint256 proposalId) external;

    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        string calldata details
    ) external returns (uint256);

    function withdrawBalance(address token, uint256 amount) external;
}

contract Transmutation {
    using SafeMath for uint256;

    // --- Constants ---
    uint256 constant MAX_UINT = 2**256 - 1;

    // --- State ---
    IMOLOCH public moloch;
    address public distributionToken;
    address public capitalToken;
    bool public initialized;

    // --- Events ---
    event Propose(uint256 proposalId, address sender);
    event Cancel(uint256 proposalId, address sender);
    event Deploy(
        address moloch,
        address distributionToken,
        address capitalToken,
        address owner
    );

    // --- Modifiers ---
    modifier memberOnly() {
        require(isMember(msg.sender), "Transmutation::not-member");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Constructor
     * @param _moloch The molochDao to propose token swaps with
     * @param _distributionToken The token to use as Moloch proposal tributeToken
     * @param _capitalToken The token to use as Moloch proposal paymentToken
     * @param _owner Address approved to transfer this contract's _distributionToken
     */
    function init(
        address _moloch,
        address _distributionToken,
        address _capitalToken,
        address _owner
    ) public {
        require(!initialized, "initialized"); 
        moloch = IMOLOCH(_moloch);
        distributionToken = _distributionToken;
        capitalToken = _capitalToken;


        emit Deploy(_moloch, _distributionToken, _capitalToken, _owner);

        // approve moloch and owner to transfer our distributionToken
        require(
            IERC20(_distributionToken).approve(_moloch, MAX_UINT),
            "Transmutation::approval-failure"
        );
        require(
            IERC20(_distributionToken).approve(_owner, MAX_UINT),
            "Transmutation::approval-failure"
        );
        initialized = true; 
    }

    // --- Public functions ---

    /**
     * @dev Triggers a withdraw of distributionToken from the Moloch
     */
    function withdrawdistributionToken() public {
        moloch.withdrawBalance(
            distributionToken,
            moloch.userTokenBalances(address(this), distributionToken)
        );
    }

    // --- Member-only functions ---

    /**
     * @dev Makes a proposal taking tribute from this contract in the form of
     * distributionToken and sending _distributionToken to _applicant as proposal payment
     * @param _applicant Recipient of the proposal's _distributionToken from the moloch
     * @param _giveAmt Amount of _distributionToken to swap for _getAmt of _distributionToken
     * @param _getAmt Amount of _capitalToken to swap for _giveAmt of _distributionToken
     * @param _details Proposal details
     */
    function propose(
        address _applicant,
        uint256 _giveAmt,
        uint256 _getAmt,
        string calldata _details
    ) external memberOnly returns (uint256) {
        // this contract cannot accept any tokens except _distributionToken
        require(
            _applicant != address(this),
            "Transmutation::invalid-applicant"
        );

        // make a Moloch proposal with _distributionToken as tributeToken and
        // _capitalToken as paymentToken
        uint256 proposalId =
            moloch.submitProposal(
                _applicant,
                0,
                0,
                _giveAmt,
                distributionToken,
                _getAmt,
                capitalToken,
                _details
            );

        emit Propose(proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @dev Cancel a Moloch proposal. Can be called by any dao member
     * @param _proposalId The id of the proposal to cancel
     */
    function cancel(uint256 _proposalId) external memberOnly {
        emit Cancel(_proposalId, msg.sender);
        moloch.cancelProposal(_proposalId);
    }

    // --- View functions ---

    /**
     * @dev Returns true if usr has voting shares in the Moloch
     * @param usr Address to check membership of
     */
    function isMember(address usr) public view returns (bool) {
        (, uint256 shares, , , , ) = moloch.members(usr);
        return shares > 0;
    }

    receive() external payable {}
}

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory {
    function createClone(address payable target)
        internal
        returns (address payable result)
    {
        // eip-1167 proxy pattern adapted for payable minion
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

contract TransmutationFactory is CloneFactory {
    address payable public immutable template; // fixed template for minion using eip-1167 proxy pattern
    address[] public minionList;
    mapping(address => AMinion) public minions;

    event SummonTransmutation(
        address indexed transmutation,
        address indexed moloch,
        address indexed owner,
        string details,
        address distributionToken,
        address capitalToken
    );

    struct AMinion {
        address moloch;
        string details;
    }

    constructor(address payable _template) {
        template = _template;
    }

    function summonTransmutation(
        address moloch,
        string memory details,
        address distributionToken,
        address capitalToken,
        address owner // dao vanilla minion
    ) external returns (address) {
        Transmutation transmutation = Transmutation(createClone(template));

        transmutation.init(moloch, distributionToken, capitalToken, owner);

        minions[address(transmutation)] = AMinion(moloch, details);
        minionList.push(address(transmutation));
        emit SummonTransmutation(
            address(transmutation),
            moloch,
            owner,
            details,
            distributionToken,
            capitalToken
        );

        return (address(transmutation));
    }
}
