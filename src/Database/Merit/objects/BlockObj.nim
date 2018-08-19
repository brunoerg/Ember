#Numerical libraries.
import ../../../lib/BN
import ../../../lib/Base

#Time library.
import ../../../lib/Time

#SHA512 library.
import ../../../lib/SHA512

#Argon library.
import ../../../lib/Argon

#Import the Merkle library.
import ../Merkle

#Define the Block class.
type Block* = ref object of RootObj
    #Argon hash of the last block.
    last: string
    #Nonce, AKA index.
    nonce: BN
    #Timestamp.
    time: BN
    #Validations.
    validations: seq[tuple[validator: string, start: int, last: int]]
    #Merkle tree.
    merkle: MerkleTree
    #Publisher address.
    publisher: string

    #Hash.
    hash: string
    #Random hex number to make sure the Argon of the hash is over the difficulty.
    proof: BN
    #Argon2d 64 character hash with the hash as the data and proof as the salt.
    argon: string

    #Who to attribute the Merit to (amount ranges from 0 to 1000).
    miners: seq[tuple[miner: string, amount: int]]
    minersHash: string
    signature: string

#Constructor.
proc newBlockObj*(
    last: string,
    nonce: BN,
    time: BN,
    validations: seq[tuple[validator: string, start: int, last: int]],
    merkle: MerkleTree,
    publisher: string,
    proof: BN,
    miners: seq[tuple[miner: string, amount: int]],
    signature: string
): Block {.raises: [].} =
    Block(
        last: last,
        nonce: nonce,
        time: time,
        validations: validations,
        merkle: merkle,
        publisher: publisher,
        proof: proof,
        miners: miners
    )

#Creates a new block without caring about the data.
proc newStartBlock*(genesis: string): Block {.raises: [ValueError, AssertionError].} =
    #Ceate the block.
    result = newBlockObj(
        "",
        newBN(),
        getTime(),
        @[],
        newMerkleTree(@[]),
        "",
        newBN(),
        @[],
        ""
    )
    #Calculate the hash.
    result.hash = SHA512(genesis)
    #Calculate the Argon hash.
    result.argon = Argon(result.hash, result.proof.toString(16))
    #Calculate the miners hash.
    result.minersHash = SHA512("00")

#Setters.
proc setHash*(blockArg: Block, hash: string) {.raises: [ValueError].} =
    if not blockArg.hash.isNil:
        raise newException(ValueError, "Double setting of the block hash.")

    blockArg.hash = hash

proc setArgon*(blockArg: Block, argon: string) {.raises: [ValueError].} =
    if not blockArg.argon.isNil:
        raise newException(ValueError, "Double setting of the block argon.")

    blockArg.argon = argon

proc setMinersHash*(blockArg: Block, minersHash: string) {.raises: [ValueError].} =
    if not blockArg.minersHash.isNil:
        raise newException(ValueError, "Double setting of the miners' hash.")

    blockArg.minersHash = minersHash

#Getters.
proc getLast*(blockArg: Block): string {.raises: [].} =
    blockArg.last
proc getNonce*(blockArg: Block): BN {.raises: [].} =
    blockArg.nonce
proc getTime*(blockArg: Block): BN {.raises: [].} =
    blockArg.time
proc getValidations*(blockArg: Block): seq[tuple[validator: string, start: int, last: int]] {.raises: [].} =
    blockArg.validations
proc getMerkle*(blockArg: Block): MerkleTree {.raises: [].} =
    blockArg.merkle
proc getPublisher*(blockArg: Block): string {.raises: [].} =
    blockArg.publisher
proc getHash*(blockArg: Block): string {.raises: [].} =
    blockArg.hash
proc getProof*(blockArg: Block): BN {.raises: [].} =
    blockArg.proof
proc getArgon*(blockArg: Block): string {.raises: [].} =
    blockArg.argon
proc getMiners*(blockArg: Block): seq[tuple[miner: string, amount: int]] {.raises: [].} =
    blockArg.miners
proc getMinersHash*(blockArg: Block): string {.raises: [].} =
    blockArg.minersHash
proc getSignature*(blockArg: Block): string {.raises: [].} =
    blockArg.signature
