pragma solidity >=0.5.14;


contract Test {

}
// pragma experimental ABIEncoderV2;

// /// @dev Helper utility library for calculating Merkle proof and managing bytes.
// library Utils {
//     /// @dev Returns the hash of a Merkle leaf node.
//     function merkleLeafHash(bytes memory _value)
//         internal
//         pure
//         returns (bytes32)
//     {
//         return sha256(abi.encodePacked(uint8(0), _value));
//     }

//     /// @dev Returns the hash of internal node, calculated from child nodes.
//     function merkleInnerHash(bytes32 _left, bytes32 _right)
//         internal
//         pure
//         returns (bytes32)
//     {
//         return sha256(abi.encodePacked(uint8(1), _left, _right));
//     }

//     /// @dev Returns the encoded bytes using signed varint encoding of the given input.
//     function encodeVarintSigned(uint256 _value)
//         internal
//         pure
//         returns (bytes memory)
//     {
//         return encodeVarintUnsigned(_value * 2);
//     }

//     /// @dev Returns the encoded bytes using unsigned varint encoding of the given input.
//     function encodeVarintUnsigned(uint256 _value)
//         internal
//         pure
//         returns (bytes memory)
//     {
//         // Computes the size of the encoded value.
//         uint256 tempValue = _value;
//         uint256 size = 0;
//         while (tempValue > 0) {
//             ++size;
//             tempValue >>= 7;
//         }
//         // Allocates the memory buffer and fills in the encoded value.
//         bytes memory result = new bytes(size);
//         tempValue = _value;
//         for (uint256 idx = 0; idx < size; ++idx) {
//             result[idx] = bytes1(uint8(128) | uint8(tempValue & 127));
//             tempValue >>= 7;
//         }
//         result[size - 1] &= bytes1(uint8(127)); // Drop the first bit of the last byte.
//         return result;
//     }
// }

// /// @dev Library for computing Tendermint's block header hash from app hash, time, and height.
// ///
// /// In Tendermint, a block header hash is the Merkle hash of a binary tree with 16 leaf nodes.
// /// Each node encodes a data piece of the blockchain. The notable data leaves are: [C] app_hash,
// /// [2] height, and [3] - time. All data pieces are combined into one 32-byte hash to be signed
// /// by block validators. The structure of the Merkle tree is shown below.
// ///
// ///                                   [BlockHeader]
// ///                                /                \
// ///                   [3A]                                    [3B]
// ///                 /      \                                /      \
// ///         [2A]                [2B]                [2C]                [2D]
// ///        /    \              /    \              /    \              /    \
// ///    [1A]      [1B]      [1C]      [1D]      [1E]      [1F]      [1G]      [1H]
// ///    /  \      /  \      /  \      /  \      /  \      /  \      /  \      /  \
// ///  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9]  [A]  [B]  [C]  [D]  [E]  [F]
// ///
// ///  [0] - version   [1] - chain_id          [2] - height                [3] - time
// ///  [4] - num_txs   [5] - total_txs         [6] - last_block_id         [7] - last_commit_hash
// ///  [8] - data_hash [9] - validators_hash   [A] - next_validators_hash  [B] - consensus_hash
// ///  [C] - app_hash  [D] - last_results_hash [E] - evidence_hash         [F] - proposer_address
// ///
// /// Notice that NOT all leaves of the Merkle tree are needed in order to compute the Merkle
// /// root hash, since we only want to validate the correctness of [C] and [2]. In fact, only
// /// [1A], [3], [2B], [2C], [D], and [1H] are needed in order to compute [BlockHeader].
// library BlockHeaderMerkleParts {
//     struct Data {
//         bytes32 versionAndChainIdHash; // [1A]
//         bytes32 timeHash; // [3]
//         bytes32 txCountAndLastBlockInfoHash; // [2B]
//         bytes32 consensusDataHash; // [2C]
//         bytes32 lastResultsHash; // [D]
//         bytes32 evidenceAndProposerHash; // [1H]
//     }

//     /// @dev Returns the block header hash after combining merkle parts with necessary data.
//     /// @param _appHash The Merkle hash of BandChain application state.
//     /// @param _blockHeight The height of this block.
//     function getBlockHeader(
//         Data memory _self,
//         bytes32 _appHash,
//         uint256 _blockHeight
//     ) internal pure returns (bytes32) {
//         return
//             Utils.merkleInnerHash( // [BlockHeader]
//                 Utils.merkleInnerHash( // [3A]
//                     Utils.merkleInnerHash( // [2A]
//                         _self.versionAndChainIdHash, // [1A]
//                         Utils.merkleInnerHash( // [1B]
//                             Utils.merkleLeafHash(
//                                 Utils.encodeVarintUnsigned(_blockHeight)
//                             ), // [2]
//                             _self.timeHash
//                         )
//                     ), // [3]
//                     _self.txCountAndLastBlockInfoHash
//                 ), // [2B]
//                 Utils.merkleInnerHash( // [3B]
//                     _self.consensusDataHash, // [2C]
//                     Utils.merkleInnerHash( // [2D]
//                         Utils.merkleInnerHash( // [1G]
//                             Utils.merkleLeafHash(
//                                 abi.encodePacked(uint8(32), _appHash)
//                             ), // [C]
//                             _self.lastResultsHash
//                         ), // [D]
//                         _self.evidenceAndProposerHash
//                     )
//                 )
//             ); // [1H]
//     }
// }

// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return sub(a, b, "SafeMath: subtraction overflow");
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      * - Subtraction cannot overflow.
//      *
//      * _Available since v2.4.0._
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage)
//         internal
//         pure
//         returns (uint256)
//     {
//         require(b <= a, errorMessage);
//         uint256 c = a - b;

//         return c;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return div(a, b, "SafeMath: division by zero");
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      * - The divisor cannot be zero.
//      *
//      * _Available since v2.4.0._
//      */
//     function div(uint256 a, uint256 b, string memory errorMessage)
//         internal
//         pure
//         returns (uint256)
//     {
//         // Solidity only automatically asserts when dividing by 0
//         require(b > 0, errorMessage);
//         uint256 c = a / b;
//         // assert(a == b * c + a % b); // There is no case in which this doesn't hold

//         return c;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * Reverts when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         return mod(a, b, "SafeMath: modulo by zero");
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * Reverts with custom message when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      * - The divisor cannot be zero.
//      *
//      * _Available since v2.4.0._
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage)
//         internal
//         pure
//         returns (uint256)
//     {
//         require(b != 0, errorMessage);
//         return a % b;
//     }
// }

// /*
//  * @dev Provides information about the current execution context, including the
//  * sender of the transaction and its data. While these are generally available
//  * via msg.sender and msg.data, they should not be accessed in such a direct
//  * manner, since when dealing with GSN meta-transactions the account sending and
//  * paying for execution may not be the actual sender (as far as an application
//  * is concerned).
//  *
//  * This contract is only required for intermediate, library-like contracts.
//  */
// contract Context {
//     // Empty internal constructor, to prevent people from mistakenly deploying
//     // an instance of this contract, which should be used via inheritance.
//     constructor() internal {}

//     // solhint-disable-previous-line no-empty-blocks

//     function _msgSender() internal view returns (address payable) {
//         return msg.sender;
//     }

//     function _msgData() internal view returns (bytes memory) {
//         this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
//         return msg.data;
//     }
// }

// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// contract Ownable is Context {
//     address private _owner;

//     event OwnershipTransferred(
//         address indexed previousOwner,
//         address indexed newOwner
//     );

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() internal {
//         _owner = _msgSender();
//         emit OwnershipTransferred(address(0), _owner);
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         require(isOwner(), "Ownable: caller is not the owner");
//         _;
//     }

//     /**
//      * @dev Returns true if the caller is the current owner.
//      */
//     function isOwner() public view returns (bool) {
//         return _msgSender() == _owner;
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public onlyOwner {
//         emit OwnershipTransferred(_owner, address(0));
//         _owner = address(0);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public onlyOwner {
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      */
//     function _transferOwnership(address newOwner) internal {
//         require(
//             newOwner != address(0),
//             "Ownable: new owner is the zero address"
//         );
//         emit OwnershipTransferred(_owner, newOwner);
//         _owner = newOwner;
//     }
// }

// /// @dev Library for computing iAVL Merkle root from (1) data leaf and (2) a list of "MerklePath"
// /// from such leaf to the root of the tree. Each Merkle path (i.e. proof component) consists of:
// ///
// /// - isDataOnRight: whether the data is on the right subtree of this internal node.
// /// - subtreeHeight: well, it is the height of this subtree.
// /// - subtreeVersion: the latest block height that this subtree has been updated.
// /// - siblingHash: 32-byte hash of the other child subtree
// ///
// /// To construct a hash of an internal Merkle node, the hashes of the two subtrees are combined
// /// with extra data of this internal node. See implementation below. Repeatedly doing this from
// /// the leaf node until you get to the root node to get the final iAVL Merkle hash.
// library IAVLMerklePath {
//     struct Data {
//         bool isDataOnRight;
//         uint8 subtreeHeight;
//         uint256 subtreeSize;
//         uint256 subtreeVersion;
//         bytes32 siblingHash;
//     }

//     /// @dev Returns the upper Merkle hash given a proof component and hash of data subtree.
//     /// @param _dataSubtreeHash The hash of data subtree up until this point.
//     function getParentHash(Data memory _self, bytes32 _dataSubtreeHash)
//         internal
//         pure
//         returns (bytes32)
//     {
//         bytes32 leftSubtree = _self.isDataOnRight
//             ? _self.siblingHash
//             : _dataSubtreeHash;
//         bytes32 rightSubtree = _self.isDataOnRight
//             ? _dataSubtreeHash
//             : _self.siblingHash;
//         return
//             sha256(
//                 abi.encodePacked(
//                     _self.subtreeHeight << 1, // Tendermint signed-int8 encoding requires multiplying by 2
//                     Utils.encodeVarintSigned(_self.subtreeSize),
//                     Utils.encodeVarintSigned(_self.subtreeVersion),
//                     uint8(32), // Size of left subtree hash
//                     leftSubtree,
//                     uint8(32), // Size of right subtree hash
//                     rightSubtree
//                 )
//             );
//     }
// }

// /// @dev Library for performing signer recovery for ECDSA secp256k1 signature. Note that the
// /// library is written specifically for signature signed on Tendermint's precommit data, which
// /// includes the block hash and some additional information prepended and appended to the block
// /// hash. The prepended part (prefix) is the same for all the signers, while the appended part
// /// (suffix) is different for each signer (including machine clock, validator index, etc).
// library TMSignature {
//     struct Data {
//         bytes32 r;
//         bytes32 s;
//         uint8 v;
//         bytes signedDataSuffix;
//     }

//     /// @dev Returns the address that signed on the given block hash.
//     /// @param _blockHash The block hash that the validator signed data on.
//     /// @param _signedDataPrefix The prefix prepended to block hash before signing.
//     function recoverSigner(
//         Data memory _self,
//         bytes32 _blockHash,
//         bytes memory _signedDataPrefix
//     ) internal pure returns (address) {
//         return
//             ecrecover(
//                 sha256(
//                     abi.encodePacked(
//                         _signedDataPrefix,
//                         _blockHash,
//                         _self.signedDataSuffix
//                     )
//                 ),
//                 _self.v,
//                 _self.r,
//                 _self.s
//             );
//     }
// }

// interface IBridge {
//     /// Helper struct to help the function caller to decode oracle data.
//     struct VerifyOracleDataResult {
//         uint64 oracleScriptId;
//         uint64 requestTime;
//         uint64 aggregationTime;
//         uint64 requestedValidatorsCount;
//         uint64 sufficientValidatorCount;
//         uint64 reportedValidatorsCount;
//         bytes params;
//         bytes data;
//     }

//     /// Performs oracle state relay and oracle data verification in one go. The caller submits
//     /// the encoded proof and receives back the decoded data, ready to be validated and used.
//     /// @param _data The encoded data for oracle state relay and data verification.
//     function relayAndVerify(bytes calldata _data)
//         external
//         returns (VerifyOracleDataResult memory result);
// }

// /// @title Bridge <3 BandChain D3N
// /// @author Band Protocol Team
// contract Bridge is IBridge, Ownable {
//     using BlockHeaderMerkleParts for BlockHeaderMerkleParts.Data;
//     using IAVLMerklePath for IAVLMerklePath.Data;
//     using TMSignature for TMSignature.Data;
//     using SafeMath for uint256;

//     /// Mapping from block height to the hash of "zoracle" iAVL Merkle tree.
//     mapping(uint256 => bytes32) public oracleStates;
//     /// Mapping from an address to its voting power.
//     mapping(address => uint256) public validatorPowers;
//     /// The total voting power of active validators currently on duty.
//     uint256 public totalValidatorPower;

//     struct ValidatorWithPower {
//         address addr;
//         uint256 power;
//     }

//     /// Initializes an oracle bridge to BandChain.
//     /// @param _validators The initial set of BandChain active validators.
//     constructor(ValidatorWithPower[] memory _validators) public {
//         for (uint256 idx = 0; idx < _validators.length; ++idx) {
//             ValidatorWithPower memory validator = _validators[idx];
//             require(
//                 validatorPowers[validator.addr] == 0,
//                 "DUPLICATION_IN_INITIAL_VALIDATOR_SET"
//             );
//             validatorPowers[validator.addr] = validator.power;
//             totalValidatorPower = totalValidatorPower.add(validator.power);
//         }
//     }

//     /// Update validator powers by owner.
//     /// @param _validators The changed set of BandChain validators.
//     function updateValidatorPowers(ValidatorWithPower[] memory _validators)
//         public
//         onlyOwner
//     {
//         for (uint256 idx = 0; idx < _validators.length; ++idx) {
//             ValidatorWithPower memory validator = _validators[idx];
//             totalValidatorPower = totalValidatorPower.sub(
//                 validatorPowers[validator.addr]
//             );
//             validatorPowers[validator.addr] = validator.power;
//             totalValidatorPower = totalValidatorPower.add(validator.power);
//         }
//     }

//     /// Relays a new oracle state to the bridge contract.
//     /// @param _blockHeight The height of block to relay to this bridge contract.
//     /// @param _oracleIAVLStateHash Hash of iAVL Merkle that represents the state of oracle store.
//     /// @param _otherStoresMerkleHash Hash of internal Merkle node for other Tendermint storages.
//     /// @param _merkleParts Extra merkle parts to compute block hash. See BlockHeaderMerkleParts lib.
//     /// @param _signedDataPrefix Prefix data prepended prior to signing block hash.
//     /// @param _signatures The signatures signed on this block, sorted alphabetically by address.
//     function relayOracleState(
//         uint256 _blockHeight,
//         bytes32 _oracleIAVLStateHash,
//         bytes32 _otherStoresMerkleHash,
//         bytes32 _supplyStoresMerkleHash,
//         BlockHeaderMerkleParts.Data memory _merkleParts,
//         bytes memory _signedDataPrefix,
//         TMSignature.Data[] memory _signatures
//     ) public {
//         // Computes Tendermint's application state hash at this given block. AppHash is actually a
//         // Merkle hash on muliple stores. Luckily, we only care about "zoracle" tree and all other
//         // stores can just be combined into one bytes32 hash off-chain.
//         //
//         //                                            ____________appHash_________
//         //                                          /                              \
//         //                   ____otherStoresMerkleHash ____                         ___innerHash___
//         //                 /                                \                     /                  \
//         //         _____ h5 ______                    ______ h6 _______        supply              zoracle
//         //       /                \                 /                  \
//         //     h1                  h2             h3                    h4
//         //     /\                  /\             /\                    /\
//         //  acc  distribution   gov  main     mint  params     slashing   staking
//         bytes32 appHash = Utils.merkleInnerHash(
//             _otherStoresMerkleHash,
//             Utils.merkleInnerHash(
//                 _supplyStoresMerkleHash,
//                 Utils.merkleLeafHash(
//                     abi.encodePacked(
//                         hex"077a6f7261636c6520", // uint8(7) + "zoracle" + uint8(32)
//                         sha256(
//                             abi.encodePacked(
//                                 sha256(abi.encodePacked(_oracleIAVLStateHash))
//                             )
//                         )
//                     )
//                 )
//             )
//         );
//         // Computes Tendermint's block header hash at this given block.
//         bytes32 blockHeader = _merkleParts.getBlockHeader(
//             appHash,
//             _blockHeight
//         );
//         // Counts the total number of valid signatures signed by active validators.
//         address lastSigner = address(0);
//         uint256 sumVotingPower = 0;
//         for (uint256 idx = 0; idx < _signatures.length; ++idx) {
//             address signer = _signatures[idx].recoverSigner(
//                 blockHeader,
//                 _signedDataPrefix
//             );
//             require(signer > lastSigner, "INVALID_SIGNATURE_SIGNER_ORDER");
//             sumVotingPower = sumVotingPower.add(validatorPowers[signer]);
//             lastSigner = signer;
//         }
//         // Verifies that sufficient validators signed the block and saves the oracle state.
//         require(
//             sumVotingPower.mul(3) > totalValidatorPower.mul(2),
//             "INSUFFICIENT_VALIDATOR_SIGNATURES"
//         );
//         oracleStates[_blockHeight] = _oracleIAVLStateHash;
//     }

//     /// Helper struct to workaround Solidity's "stack too deep" problem.
//     struct VerifyOracleDataLocalVariables {
//         bytes encodedVarint;
//         bytes32 dataHash;
//     }

//     /// Decodes the encoded result and returns back the decoded data which is the data and its context.
//     /// @param _encodedData The encoded of result and its context.
//     function decodeResult(bytes memory _encodedData)
//         public
//         pure
//         returns (VerifyOracleDataResult memory)
//     {
//         require(_encodedData.length > 40, "INPUT_MUST_BE_LONGER_THAN_40_BYTES");

//         VerifyOracleDataResult memory result;
//         assembly {
//             mstore(
//                 add(result, 0x20),
//                 and(mload(add(_encodedData, 0x08)), 0xffffffffffffffff)
//             )
//             mstore(
//                 add(result, 0x40),
//                 and(mload(add(_encodedData, 0x10)), 0xffffffffffffffff)
//             )
//             mstore(
//                 add(result, 0x60),
//                 and(mload(add(_encodedData, 0x18)), 0xffffffffffffffff)
//             )
//             mstore(
//                 add(result, 0x80),
//                 and(mload(add(_encodedData, 0x20)), 0xffffffffffffffff)
//             )
//             mstore(
//                 add(result, 0xa0),
//                 and(mload(add(_encodedData, 0x28)), 0xffffffffffffffff)
//             )
//         }

//         bytes memory data = new bytes(_encodedData.length - 40);
//         uint256 dataLengthInWords = ((data.length - 1) / 32) + 1;
//         for (uint256 i = 0; i < dataLengthInWords; i++) {
//             assembly {
//                 mstore(
//                     add(data, add(0x20, mul(i, 0x20))),
//                     mload(add(_encodedData, add(0x48, mul(i, 0x20))))
//                 )
//             }
//         }
//         result.data = data;

//         return result;
//     }

//     /// Verifies that the given data is a valid data on BandChain as of the given block height.
//     /// @param _blockHeight The block height. Someone must already relay this block.
//     /// @param _data The data to verify, with the format similar to what on the blockchain store.
//     /// @param _requestId The ID of request for this data piece.
//     /// @param _version Lastest block height that the data node was updated.
//     /// @param _merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
//     function verifyOracleData(
//         uint256 _blockHeight,
//         bytes memory _data,
//         uint64 _requestId,
//         uint64 _oracleScriptId,
//         bytes memory _params,
//         uint256 _version,
//         IAVLMerklePath.Data[] memory _merklePaths
//     ) public view returns (VerifyOracleDataResult memory) {
//         bytes32 oracleStateRoot = oracleStates[_blockHeight];
//         require(
//             oracleStateRoot != bytes32(uint256(0)),
//             "NO_ORACLE_ROOT_STATE_DATA"
//         );
//         // Computes the hash of leaf node for iAVL oracle tree.
//         VerifyOracleDataLocalVariables memory vars;
//         vars.encodedVarint = Utils.encodeVarintSigned(_version);
//         vars.dataHash = sha256(_data);
//         bytes32 currentMerkleHash = sha256(
//             abi.encodePacked(
//                 uint8(0), // Height of tree (only leaf node) is 0 (signed-varint encode)
//                 uint8(2), // Size of subtree is 1 (signed-varint encode)
//                 vars.encodedVarint,
//                 uint8(17 + _params.length), // Size of data key (1-byte constant 0x01 + 8-byte request ID + 8-byte oracleScriptId + length of params)
//                 uint8(255), // Constant 0xff prefix data request info storage key
//                 _requestId,
//                 _oracleScriptId,
//                 _params,
//                 uint8(32), // Size of data hash
//                 vars.dataHash
//             )
//         );
//         // Goes step-by-step computing hash of parent nodes until reaching root node.
//         for (uint256 idx = 0; idx < _merklePaths.length; ++idx) {
//             currentMerkleHash = _merklePaths[idx].getParentHash(
//                 currentMerkleHash
//             );
//         }
//         // Verifies that the computed Merkle root matches what currently exists.
//         require(
//             currentMerkleHash == oracleStateRoot,
//             "INVALID_ORACLE_DATA_PROOF"
//         );

//         VerifyOracleDataResult memory result = decodeResult(_data);
//         result.params = _params;
//         result.oracleScriptId = _oracleScriptId;

//         return result;
//     }

//     /// Performs oracle state relay and oracle data verification in one go. The caller submits
//     /// the encoded proof and receives back the decoded data, ready to be validated and used.
//     /// @param _data The encoded data for oracle state relay and data verification.
//     function relayAndVerify(bytes calldata _data)
//         external
//         returns (VerifyOracleDataResult memory result)
//     {
//         (bytes memory relayData, bytes memory verifyData) = abi.decode(
//             _data,
//             (bytes, bytes)
//         );
//         (bool relayOk, ) = address(this).call(
//             abi.encodePacked(this.relayOracleState.selector, relayData)
//         );
//         require(relayOk, "RELAY_ORACLE_STATE_FAILED");
//         (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
//             abi.encodePacked(this.verifyOracleData.selector, verifyData)
//         );
//         require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
//         return abi.decode(verifyResult, (VerifyOracleDataResult));
//     }
// }

// 1 .calldata for testing
// 0xad37373200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000ac00000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000054000000000000000000000000000000000000000000000000000000000000004e0000000000000000000000000000000000000000000000000000000000000043e1f8ccf68b355092fdf91b6b694edbebee5dad05e109c8160eb29462bdc995117937ae0536e33a2e7b9fcbfc0b28e25ae685532f5254c5203d70921a98ad6cb981060c95592d64d0536b79656a77eac4f0ef4074a1fa634b03795b4fd60725f3b32fa694879095840619f5e49380612bd296ff7e950eafb66ff654d99ca70869ecf8f212876bc79e8a95b695d05623b66363130654bcef439d8c901eadd2478587513ffe6590484ca8be5dc089f44e8df323449d5be57f4918ec0c4b8c568b3b565269fcfb0cc5557e5ecc5ea493900f7fd48aa99a255d49b38bbb0d1697c8e526e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d7f4be7e5a1eb872ad44103360ddc190410331280c42a54d829a5d752c796685d000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000000106e0802113e0400000000000022480a20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000220c78cf546cfaa125473e81adc773123fd6840d0f08dc52e8b9a829917e76444d348c64c8cca117b0b2d751a1c20a9541f5372e3b2fad2f53ec1ffc9e6b7167ce7000000000000000000000000000000000000000000000000000000000000001b0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003f12240a20cc19b175ccd7b0ad1c8cf7d9fb0fbefd327fd09410e0e7926f11864dad6d723710012a0c08a2c0bdf30510b1c482ba03320962616e64636861696e003ccd5bd8fe505abdd8901a5c6f608ac91aae266fb6254666d986c27e3d30e6857bf6e1637ce43e229d0e5322e8d55004d814fd23423e41f8392896d555875bda000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003f12240a20cc19b175ccd7b0ad1c8cf7d9fb0fbefd327fd09410e0e7926f11864dad6d723710012a0c08a2c0bdf30510bbfadaba03320962616e64636861696e003ecb129f7bcddef6a6cf9c02b443f1f564242b9dc2b9cd0959e6649bac8564bf5a4cb8503a0ffeca3404f1f865c7d4aa49d3272aa3df39afe07a8660029fdacb000000000000000000000000000000000000000000000000000000000000001c0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000003f12240a20cc19b175ccd7b0ad1c8cf7d9fb0fbefd327fd09410e0e7926f11864dad6d723710012a0c08a2c0bdf30510f6a7eeba03320962616e64636861696e000000000000000000000000000000000000000000000000000000000000000560000000000000000000000000000000000000000000000000000000000000043e00000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000003a500000000000000000000000000000000000000000000000000000000000001800000000000000000000000000000000000000000000000000000000000000030000000005e6f5f15000000005e6f5f5500000000000000040000000000000004000000000000000400000000000029840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034554480000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000003a5b970d52c0d68a1741bc481581c245b3ca04b0596b1a0c8a113583ecf7cad5c2b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000003a58f137c3f314784dad9866e0ac08543a7d0a9cf924f9fd6d71f36c7337c534d1100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000003a54d40a32f8deb619363e5010c1a4e19f6137f321313777c1334a262b9f044728500000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000000000000000000000000003a557fe63ef72b1c2af472e9f409ffc31540b13bd9553d736534ddc7f1041c36bce00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000003a5580726819fa6a8cd409b12a6ebec0fec2754ddd3c6cab874f10a684db9c1117f00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000002c000000000000000000000000000000000000000000000000000000000000043d34b30f702e922512108a2416d25cbf3639d2f82b338a2f76b3f47073ca7d20c6
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// 2. working contract address
// 0x6560b63f06A0645386cb9079CD45EEa7AC937C09
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// 3. After calling with the calldata in 1., please check oracleState using this following calldata
// 0xc5f556f0000000000000000000000000000000000000000000000000000000000000043e
