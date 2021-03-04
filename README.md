# MinionSummoner
Summon All the Minions

## Summoning 
Summon a minion for your DAO, give it a name, in this case it is the transmuations minion. 

Summoning a minion is easy. see Constructor section for info around aurguments.

Details of summoned minions can be looked up in the minions mapping, which will allow you to search by minion address and retrieve information about the minion's description and the Moloch it serves. 

## Transmutation

> "Moloch whose blood is running money!"

Transmutation is a contract that enables the process for CCO funding proposals.
The `distributionToken` is slowly traded into the Dao as `capitalToken` is used.

The Transmutation contract holds `distributionToken` (e.g. HAUS) which can only be distributed through Dao proposals (with owner approval to transfer as a fail-safe).
The `distributionToken` is swapped with the Dao for `capitalToken` (held in the Dao) through moloch proposals.
If passed, these proposals will send `distributionToken` as tribute to the Dao and allow some `applicant` address to withdraw the proposed amount of `capitalToken`.
The rate of `distributionToken` to `capitalToken` for a valid proposal will be set based on social consensus within the Dao.

### Comments and known issues

When a proposal is made through the Transmutation contract, the proposed amount of `distributionToken` is immediately locked up in the Dao.
After a failed or cancelled proposal through the Transmutation contract, `Transmutation.withdrawdistributionToken` must be called to retrieve these tokens.
As a result of this dynamic, any address that holds voting shares in the moloch can cancel any Transmutation proposal until the proposal is sponsored.
Members with voting shares can also atomically call `Transmutation.propose` followed by `Moloch.sponsorProposal`, which would allow locking up any amount of `distributionToken` until the proposal is voted down.
The expected response to this would be to `guildKick` the proposer from the Dao, but the member would retain their voting shares until the `guildKick` proposal was processed, meaning they could likely perform the same attack a second time immediately after the griefing proposal is processed.
In short, a rogue Dao member could lock all of the Transmutation contract's `distributionToken` for up to two Dao voting periods.

## Constructor (Init)

    constructor(
        address _moloch,
        address _distributionToken,
        address _capitalToken,
        address _owner
    )

* The constructor takes The DAO address (_moloch).
* The token (_distributionToken) which is held by this contract and is used to replace funds when the payment token is requested in a proposal.
* The token address (_capitalToken) that is considered the 'payment token' for the round .
* The owner of the contract (_owner). Should be a Minion

Both the DAO and the Minion are approved to move funds from this contract. The DAO must be approved to so this contract can make tribute to it through a proposal. And the Minion Owner is approved so tokens can be pulled out of this contract by a DAO proposal.

## Public Functions

`  function withdrawdistributionToken()`

this is for the case where the dao sends some tokens to this contract through a proposal. This contract must be able to call withdrawBalance

## Member Only Functions

`  function cancel(uint256 _proposalId) external`

if a proposal is made in error this allows any DAO member to cancel it. Avoiding having to sponsored the proposal and then vote it down.

    function propose(
        address _applicant,
        uint256 _giveAmt,
        uint256 _getAmt,
        string calldata _details
    )

This is a wrapper around the moloch submitProposal function. It will ask for payment in the capitalToken and give tribute in the distributionToken. _details is a param to collect a short desctiption.

## Events

    event Propose(uint256 proposalId, address sender);
    event Cancel(uint256 proposalId, address sender);
    event Deploy(
        address moloch,
        address distributionToken,
        address capitalToken,
        address owner
    );

## Deployments

xDAI - 0xf88eaD028100529a540122456A68CA3ca416ccA3

kovan - 0x235320BEfFB2c3ca8f4b2b428dF7b740009cF16c

rinkeby - 

mainnet - 
