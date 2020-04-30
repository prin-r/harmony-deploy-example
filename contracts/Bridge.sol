pragma solidity >=0.5.14;
pragma experimental ABIEncoderV2;


/// @dev Helper utility library for calculating Merkle proof and managing bytes.
library Utils {
    /// @dev Returns the hash of a Merkle leaf node.
    function merkleLeafHash(bytes memory _value)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(0), _value));
    }

    /// @dev Returns the hash of internal node, calculated from child nodes.
    function merkleInnerHash(bytes32 _left, bytes32 _right)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(1), _left, _right));
    }

    /// @dev Returns the encoded bytes using signed varint encoding of the given input.
    function encodeVarintSigned(uint256 _value)
        internal
        pure
        returns (bytes memory)
    {
        return encodeVarintUnsigned(_value * 2);
    }

    /// @dev Returns the encoded bytes using unsigned varint encoding of the given input.
    function encodeVarintUnsigned(uint256 _value)
        internal
        pure
        returns (bytes memory)
    {
        // Computes the size of the encoded value.
        uint256 tempValue = _value;
        uint256 size = 0;
        while (tempValue > 0) {
            ++size;
            tempValue >>= 7;
        }
        // Allocates the memory buffer and fills in the encoded value.
        bytes memory result = new bytes(size);
        tempValue = _value;
        for (uint256 idx = 0; idx < size; ++idx) {
            result[idx] = bytes1(uint8(128) | uint8(tempValue & 127));
            tempValue >>= 7;
        }
        result[size - 1] &= bytes1(uint8(127)); // Drop the first bit of the last byte.
        return result;
    }
}


/// @dev Library for computing Tendermint's block header hash from app hash, time, and height.
///
/// In Tendermint, a block header hash is the Merkle hash of a binary tree with 14 leaf nodes.
/// Each node encodes a data piece of the blockchain. The notable data leaves are: [A] app_hash,
/// [2] height, and [3] - time. All data pieces are combined into one 32-byte hash to be signed
/// by block validators. The structure of the Merkle tree is shown below.
///
///                                   [BlockHeader]
///                                /                \
///                   [3A]                                    [3B]
///                 /      \                                /      \
///         [2A]                [2B]                [2C]                [2D]
///        /    \              /    \              /    \              /    \
///    [1A]      [1B]      [1C]      [1D]      [1E]      [1F]        [C]    [D]
///    /  \      /  \      /  \      /  \      /  \      /  \
///  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9]  [A]  [B]
///
///  [0] - version               [1] - chain_id            [2] - height        [3] - time
///  [4] - last_block_id         [5] - last_commit_hash    [6] - data_hash     [7] - validators_hash
///  [8] - next_validators_hash  [9] - consensus_hash      [A] - app_hash      [B] - last_results_hash
///  [C] - evidence_hash         [D] - proposer_address
///
/// Notice that NOT all leaves of the Merkle tree are needed in order to compute the Merkle
/// root hash, since we only want to validate the correctness of [A] and [2]. In fact, only
/// [1A], [3], [2B], [1E], [B], and [2D] are needed in order to compute [BlockHeader].
library BlockHeaderMerkleParts {
    struct Data {
        bytes32 versionAndChainIdHash; // [1A]
        bytes32 timeHash; // [3]
        bytes32 lastBlockIDAndOther; // [2B]
        bytes32 nextValidatorHashAndConsensusHash; // [1E]
        bytes32 lastResultsHash; // [B]
        bytes32 evidenceAndProposerHash; // [2D]
    }

    /// @dev Returns the block header hash after combining merkle parts with necessary data.
    /// @param _appHash The Merkle hash of BandChain application state.
    /// @param _blockHeight The height of this block.
    function getBlockHeader(
        Data memory _self,
        bytes32 _appHash,
        uint256 _blockHeight
    ) internal pure returns (bytes32) {
        return
            Utils.merkleInnerHash( // [BlockHeader]
                Utils.merkleInnerHash( // [3A]
                    Utils.merkleInnerHash( // [2A]
                        _self.versionAndChainIdHash, // [1A]
                        Utils.merkleInnerHash( // [1B]
                            Utils.merkleLeafHash( // [2]
                                Utils.encodeVarintUnsigned(_blockHeight)
                            ),
                            _self.timeHash // [3]
                        )
                    ),
                    _self.lastBlockIDAndOther // [2B]
                ),
                Utils.merkleInnerHash( // [3B]
                    Utils.merkleInnerHash( // [2C]
                        _self.nextValidatorHashAndConsensusHash, // [1E]
                        Utils.merkleInnerHash( // [1F]
                            Utils.merkleLeafHash( // [A]
                                abi.encodePacked(uint8(32), _appHash)
                            ),
                            _self.lastResultsHash // [B]
                        )
                    ),
                    _self.evidenceAndProposerHash // [2D]
                )
            );
    }
}


// Computes Tendermint's application state hash at this given block. AppHash is actually a
// Merkle hash on muliple stores.
//                         ________________[AppHash]_______________
//                        /                                        \
//             _______[I11]______                         ________[I12]________
//            /                  \                       /                     \
//       __[I7]__             __[I8]__              __[I9]__               __[I10]__
//      /         \          /         \           /         \            /           \
//    [I1]       [I2]     [I3]        [I4]       [I5]        [I6]       [C]          [D]
//   /   \      /   \    /    \      /    \     /    \       /   \
// [0]   [1]  [2]   [3] [4]   [5]  [6]    [7] [8]    [9]   [A]   [B]
// [0] - acc     [1] - bank      [2] - capability [3] - distribution  [4] - evidence
// [5] - gov     [6] - ibc       [7] - mem_cap    [8] - mint          [9] - oracle
// [A] - params  [B] - slashing  [C] - staking    [D] - upgrade
// Notice that NOT all leaves of the Merkle tree are needed in order to compute the Merkle
// root hash, since we only want to validate the correctness of [9] In fact, only
// [I11], [8], [9], [I6], and [I10] are needed in order to compute [AppHash].

library MultiStore {
    struct Data {
        bytes32 accToMemCapStoresMerkleHash; // [I11]
        bytes32 mintStoresMerkleHash; // [8]
        bytes32 oracleIAVLStateHash; // [9]
        bytes32 paramsAndSlashingStoresMerkleHash; // [I6]
        bytes32 stakingAndUpgradeStoresMerkleHash; // [I10]
    }

    function getAppHash(Data memory _self) internal pure returns (bytes32) {
        return
            Utils.merkleInnerHash( // [AppHash]
                _self.accToMemCapStoresMerkleHash, // [I11]
                Utils.merkleInnerHash( // [I12]
                    Utils.merkleInnerHash( // [I9]
                        Utils.merkleInnerHash( // [I5]
                            _self.mintStoresMerkleHash, // [8]
                            Utils.merkleLeafHash( // [9]
                                abi.encodePacked(
                                    hex"066f7261636c6520", // oracle prefix (uint8(6) + "oracle" + uint8(32))
                                    sha256(
                                        abi.encodePacked(
                                            sha256(
                                                abi.encodePacked(
                                                    _self.oracleIAVLStateHash
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        ),
                        _self.paramsAndSlashingStoresMerkleHash // [I6]
                    ),
                    _self.stakingAndUpgradeStoresMerkleHash // [I10]
                )
            );
    }
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/// @dev Library for computing iAVL Merkle root from (1) data leaf and (2) a list of "MerklePath"
/// from such leaf to the root of the tree. Each Merkle path (i.e. proof component) consists of:
///
/// - isDataOnRight: whether the data is on the right subtree of this internal node.
/// - subtreeHeight: well, it is the height of this subtree.
/// - subtreeVersion: the latest block height that this subtree has been updated.
/// - siblingHash: 32-byte hash of the other child subtree
///
/// To construct a hash of an internal Merkle node, the hashes of the two subtrees are combined
/// with extra data of this internal node. See implementation below. Repeatedly doing this from
/// the leaf node until you get to the root node to get the final iAVL Merkle hash.
library IAVLMerklePath {
    struct Data {
        bool isDataOnRight;
        uint8 subtreeHeight;
        uint256 subtreeSize;
        uint256 subtreeVersion;
        bytes32 siblingHash;
    }

    /// @dev Returns the upper Merkle hash given a proof component and hash of data subtree.
    /// @param _dataSubtreeHash The hash of data subtree up until this point.
    function getParentHash(Data memory _self, bytes32 _dataSubtreeHash)
        internal
        pure
        returns (bytes32)
    {
        bytes32 leftSubtree = _self.isDataOnRight
            ? _self.siblingHash
            : _dataSubtreeHash;
        bytes32 rightSubtree = _self.isDataOnRight
            ? _dataSubtreeHash
            : _self.siblingHash;
        return
            sha256(
                abi.encodePacked(
                    _self.subtreeHeight << 1, // Tendermint signed-int8 encoding requires multiplying by 2
                    Utils.encodeVarintSigned(_self.subtreeSize),
                    Utils.encodeVarintSigned(_self.subtreeVersion),
                    uint8(32), // Size of left subtree hash
                    leftSubtree,
                    uint8(32), // Size of right subtree hash
                    rightSubtree
                )
            );
    }
}


/// @dev Library for performing signer recovery for ECDSA secp256k1 signature. Note that the
/// library is written specifically for signature signed on Tendermint's precommit data, which
/// includes the block hash and some additional information prepended and appended to the block
/// hash. The prepended part (prefix) is the same for all the signers, while the appended part
/// (suffix) is different for each signer (including machine clock, validator index, etc).
library TMSignature {
    struct Data {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes signedDataSuffix;
    }

    /// @dev Returns the address that signed on the given block hash.
    /// @param _blockHash The block hash that the validator signed data on.
    /// @param _signedDataPrefix The prefix prepended to block hash before signing.
    function recoverSigner(
        Data memory _self,
        bytes32 _blockHash,
        bytes memory _signedDataPrefix
    ) internal pure returns (address) {
        return
            ecrecover(
                sha256(
                    abi.encodePacked(
                        _signedDataPrefix,
                        _blockHash,
                        _self.signedDataSuffix
                    )
                ),
                _self.v,
                _self.r,
                _self.s
            );
    }
}


interface IBridge {
    /// Request packet struct is similar packet on Bandchain using to re-calculate result hash.
    struct RequestPacket {
        string clientId;
        uint64 oracleScriptId;
        string params;
        uint64 askCount;
        uint64 minCount;
    }

    /// Response packet struct is similar packet on Bandchain using to re-calculate result hash.
    struct ResponsePacket {
        string clientId;
        uint64 requestId;
        uint64 ansCount;
        uint64 requestTime;
        uint64 resolveTime;
        uint8 resolveStatus;
        string result;
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param _data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata _data)
        external
        returns (RequestPacket memory, ResponsePacket memory);
}


library Packets {
    function marshalRequestPacket(IBridge.RequestPacket memory _self)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                hex"d9c58927", // Amino codec info for RequestPacket type
                uint8(10), // (1 << 3) | 2
                getEncodeLength(_self.clientId),
                _self.clientId,
                uint8(16), // (2 << 3) | 0
                Utils.encodeVarintUnsigned(_self.oracleScriptId),
                uint8(26), // (3 << 3) | 2
                getEncodeLength(_self.params),
                _self.params,
                uint8(32), // (4 << 3) | 0
                Utils.encodeVarintUnsigned(_self.askCount),
                uint8(40), // (5 << 3) | 0
                Utils.encodeVarintUnsigned(_self.minCount)
            );
    }

    function getEncodeLength(string memory _s)
        internal
        pure
        returns (bytes memory)
    {
        return Utils.encodeVarintUnsigned(bytes(_s).length);
    }

    function getReponsePart1(
        string memory _clientId,
        uint64 _requestId,
        uint64 _ansCount,
        uint64 _requestTime
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                uint8(10), // (1 << 3) | 2
                getEncodeLength(_clientId),
                _clientId,
                uint8(16), // (2 << 3) | 0
                Utils.encodeVarintUnsigned(_requestId),
                uint8(24), // (3 << 3) | 0
                Utils.encodeVarintUnsigned(_ansCount),
                uint8(32), // (4 << 3) | 0
                Utils.encodeVarintUnsigned(_requestTime)
            );
    }

    function getReponsePart2(
        uint64 _resolveTime,
        uint8 _resolveStatus,
        string memory _result
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                uint8(40), // (5 << 3) | 0
                Utils.encodeVarintUnsigned(_resolveTime),
                uint8(48), // (6 << 3) | 0
                Utils.encodeVarintSigned(_resolveStatus),
                uint8(58), // (7 << 3) | 2
                getEncodeLength(_result),
                _result
            );
    }

    function marshalResponsePacket(IBridge.ResponsePacket memory _self)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                hex"79b5957c", // Amino codec info for ResponsePacket type
                getReponsePart1(
                    _self.clientId,
                    _self.requestId,
                    _self.ansCount,
                    _self.requestTime
                ),
                getReponsePart2(
                    _self.resolveTime,
                    _self.resolveStatus,
                    _self.result
                )
            );
    }

    function getResultHash(
        IBridge.RequestPacket memory _req,
        IBridge.ResponsePacket memory _res
    ) internal pure returns (bytes32) {
        return
            sha256(
                abi.encodePacked(
                    sha256(marshalRequestPacket(_req)),
                    sha256(marshalResponsePacket(_res))
                )
            );
    }
}


contract Bridge is IBridge, Ownable {
    using BlockHeaderMerkleParts for BlockHeaderMerkleParts.Data;
    using MultiStore for MultiStore.Data;
    using IAVLMerklePath for IAVLMerklePath.Data;
    using TMSignature for TMSignature.Data;
    using SafeMath for uint256;

    /// Mapping from block height to the hash of "zoracle" iAVL Merkle tree.
    mapping(uint256 => bytes32) public oracleStates;
    /// Mapping from an address to its voting power.
    mapping(address => uint256) public validatorPowers;
    /// The total voting power of active validators currently on duty.
    uint256 public totalValidatorPower;

    struct ValidatorWithPower {
        address addr;
        uint256 power;
    }

    /// Initializes an oracle bridge to BandChain.
    /// @param _validators The initial set of BandChain active validators.
    constructor(ValidatorWithPower[] memory _validators) public {
        for (uint256 idx = 0; idx < _validators.length; ++idx) {
            ValidatorWithPower memory validator = _validators[idx];
            require(
                validatorPowers[validator.addr] == 0,
                "DUPLICATION_IN_INITIAL_VALIDATOR_SET"
            );
            validatorPowers[validator.addr] = validator.power;
            totalValidatorPower = totalValidatorPower.add(validator.power);
        }
    }

    /// Update validator powers by owner.
    /// @param _validators The changed set of BandChain validators.
    function updateValidatorPowers(ValidatorWithPower[] memory _validators)
        public
        onlyOwner
    {
        for (uint256 idx = 0; idx < _validators.length; ++idx) {
            ValidatorWithPower memory validator = _validators[idx];
            totalValidatorPower = totalValidatorPower.sub(
                validatorPowers[validator.addr]
            );
            validatorPowers[validator.addr] = validator.power;
            totalValidatorPower = totalValidatorPower.add(validator.power);
        }
    }

    /// Relays a new oracle state to the bridge contract.
    /// @param _blockHeight The height of block to relay to this bridge contract.
    /// @param _multiStore Extra multi store to compute app hash. See MultiStore lib.
    /// @param _merkleParts Extra merkle parts to compute block hash. See BlockHeaderMerkleParts lib.
    /// @param _signedDataPrefix Prefix data prepended prior to signing block hash.
    /// @param _signatures The signatures signed on this block, sorted alphabetically by address.
    function relayOracleState(
        uint256 _blockHeight,
        MultiStore.Data memory _multiStore,
        BlockHeaderMerkleParts.Data memory _merkleParts,
        bytes memory _signedDataPrefix,
        TMSignature.Data[] memory _signatures
    ) public {
        bytes32 appHash = _multiStore.getAppHash();
        // Computes Tendermint's block header hash at this given block.
        bytes32 blockHeader = _merkleParts.getBlockHeader(
            appHash,
            _blockHeight
        );
        // Counts the total number of valid signatures signed by active validators.
        address lastSigner = address(0);
        uint256 sumVotingPower = 0;
        for (uint256 idx = 0; idx < _signatures.length; ++idx) {
            address signer = _signatures[idx].recoverSigner(
                blockHeader,
                _signedDataPrefix
            );
            require(signer > lastSigner, "INVALID_SIGNATURE_SIGNER_ORDER");
            sumVotingPower = sumVotingPower.add(validatorPowers[signer]);
            lastSigner = signer;
        }
        // Verifies that sufficient validators signed the block and saves the oracle state.
        require(
            sumVotingPower.mul(3) > totalValidatorPower.mul(2),
            "INSUFFICIENT_VALIDATOR_SIGNATURES"
        );
        oracleStates[_blockHeight] = _multiStore.oracleIAVLStateHash;
    }

    /// Helper struct to workaround Solidity's "stack too deep" problem.
    struct VerifyOracleDataLocalVariables {
        bytes encodedVarint;
        bytes32 dataHash;
    }

    /// Verifies that the given data is a valid data on BandChain as of the given block height.
    /// @param _blockHeight The block height. Someone must already relay this block.
    /// @param _requestPacket The request packet is this request.
    /// @param _responsePacket The response packet of this request.
    /// @param _version Lastest block height that the data node was updated.
    /// @param _merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyOracleData(
        uint256 _blockHeight,
        RequestPacket memory _requestPacket,
        ResponsePacket memory _responsePacket,
        uint256 _version,
        IAVLMerklePath.Data[] memory _merklePaths
    ) public view returns (RequestPacket memory, ResponsePacket memory) {
        bytes32 oracleStateRoot = oracleStates[_blockHeight];
        require(
            oracleStateRoot != bytes32(uint256(0)),
            "NO_ORACLE_ROOT_STATE_DATA"
        );
        // Computes the hash of leaf node for iAVL oracle tree.
        VerifyOracleDataLocalVariables memory vars;
        vars.encodedVarint = Utils.encodeVarintSigned(_version);
        vars.dataHash = sha256(
            abi.encodePacked(
                Packets.getResultHash(_requestPacket, _responsePacket)
            )
        );
        bytes32 currentMerkleHash = sha256(
            abi.encodePacked(
                uint8(0), // Height of tree (only leaf node) is 0 (signed-varint encode)
                uint8(2), // Size of subtree is 1 (signed-varint encode)
                vars.encodedVarint,
                uint8(9), // Size of data key (1-byte constant 0x01 + 8-byte request ID)
                uint8(255), // Constant 0xff prefix data request info storage key
                _responsePacket.requestId,
                uint8(32), // Size of data hash
                vars.dataHash
            )
        );
        // Goes step-by-step computing hash of parent nodes until reaching root node.
        for (uint256 idx = 0; idx < _merklePaths.length; ++idx) {
            currentMerkleHash = _merklePaths[idx].getParentHash(
                currentMerkleHash
            );
        }
        // Verifies that the computed Merkle root matches what currently exists.
        require(
            currentMerkleHash == oracleStateRoot,
            "INVALID_ORACLE_DATA_PROOF"
        );

        return (_requestPacket, _responsePacket);
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param _data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata _data)
        external
        returns (RequestPacket memory, ResponsePacket memory)
    {
        (bytes memory relayData, bytes memory verifyData) = abi.decode(
            _data,
            (bytes, bytes)
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayOracleState.selector, relayData)
        );
        require(relayOk, "RELAY_ORACLE_STATE_FAILED");
        (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
            abi.encodePacked(this.verifyOracleData.selector, verifyData)
        );
        require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
        return abi.decode(verifyResult, (RequestPacket, ResponsePacket));
    }
}

// 1 .calldata for testing
// 0xad37373200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000b60000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000005800000000000000000000000000000000000000000000000000000000000000520000000000000000000000000000000000000000000000000000000000000001c98d5a295127bd633fe41a1a32694efd02cc28bbee3ce47d1252b83221004198738f6b13c2200fb17eef5f64be9a054d973be7d9689649a0cfe870b238264b6a6d3707bec5bf767c06d08e6ac3bb09a249d3c7a12cc5534d1010e7f5712f00f3859d16cb43e4cfd60fa4722a3af0d8f785f8f5cd2d3c65ad920d9f93054ec609ad09d2b170ded61cb985677443047a71911d0c5817437eaf473766798c2d5025032fa694879095840619f5e49380612bd296ff7e950eafb66ff654d99ca70869ebc48eb9e63c669d292008d1f286265a942b79b0b1744bc627a5ca0693b2acfef770103e37bcf669e84ca7787d9f19e669d7ecd4f4b80da4a50477bbcc2afe477004209a161040ab1778e2f2c00ee482f205b28efba439fcb04ea283f619478d94deac164a916c49f6591b2b05cc63ff5d8cf10d82f03f7acc295ec4183fd37e90efe3e12f46363c7779140d4ce659925db52f19053e114d7cc4efd666b37f79f00000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000106d0802111c0000000000000022480a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000002205d0fdd871b479ba5e7c46edf17fa6360e42c7231948443aff1d72e9b996a957a662cd2e89090aeab58ce7dc51a02f579418201dc38d4970614c4a88bd5677e24000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003e12240a209c7a986f99ff1bf3cfc599b57e608c48601478a300aa03f3dde3e2a6275140be10012a0b08ab8ba6f50510d4c3b51e320962616e64636861696e000062f89b3e7ab41f6ff71b1f097b055a8033089e4bfeac0a42656ba4ece4d370e66c3c01cbe588fea9187fd06e07619dabc410155c41985a63c401f4d167820e3e000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003e12240a209c7a986f99ff1bf3cfc599b57e608c48601478a300aa03f3dde3e2a6275140be10012a0b08ab8ba6f50510c0dae21f320962616e64636861696e000081cec8b6b9d4a0f737def3ef29b3c4dae24612c675ae17bf29c720aac1c8b6ab2a34de8f41bfee200872fcecbed0c1351d2ed128bcced61e940265014d7f7ffc000000000000000000000000000000000000000000000000000000000000001b0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003e12240a209c7a986f99ff1bf3cfc599b57e608c48601478a300aa03f3dde3e2a6275140be10012a0b08ab8ba6f50510d0d08c1f320962616e64636861696e000000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000962616e6420746573740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e303330303030303034323534343336343030303030303030303030303030000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000005ea985a2000000000000000000000000000000000000000000000000000000005ea985a800000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000962616e6420746573740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001035636133306330303030303030303030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001bd1814868ab070be64030d05681ebbaa8394251d3fd3a677aa839233ca6ec1c9d000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001b48ead2de2ed08b9e45637904a213b3a92bb90c5f70d89e3ebee8a369da6c25ab000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001b709e1c73511b24efdd9b8d3cd717a5210ba20e2411a8529e8b642c54fb002dc4000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000015000000000000000000000000000000000000000000000000000000000000001be06e281da7e25786b4997b6289d896e07e0f1a4eadda7dfd9074f1d6bd7cc445
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// 2. working contract address
// 0xC4C777c8eB7Bb95606Abe89b36C0BF5c9EBcAB18
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// 3. After calling with the calldata in 1., please check oracleState using this following calldata
// 0xc5f556f0000000000000000000000000000000000000000000000000000000000000001c
