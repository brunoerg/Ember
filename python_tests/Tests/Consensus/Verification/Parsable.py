#Tests proper handling of Verifications with unsynced Transactions which are parsable yet have invalid signatures.

#Types.
from typing import Dict, IO, Any

#Data class.
from python_tests.Classes.Transactions.Data import Data

#Consensus classes.
from python_tests.Classes.Consensus.Verification import SignedVerification
from python_tests.Classes.Consensus.Consensus import Consensus

#Blockchain class.
from python_tests.Classes.Merit.Blockchain import Blockchain

#TestError Exception.
from python_tests.Tests.Errors import TestError

#Meros classes.
from python_tests.Meros.Meros import MessageType
from python_tests.Meros.RPC import RPC

#Merit and Consensus verifiers.
from python_tests.Tests.Merit.Verify import verifyBlockchain
from python_tests.Tests.Consensus.Verify import verifyConsensus

#JSON standard lib.
import json

def VParsable(
    rpc: RPC
) -> None:
    file: IO[Any] = open("python_tests/Vectors/Consensus/Verification/Parsable.json", "r")
    vectors: Dict[str, Any] = json.loads(file.read())
    #Data.
    data: Data = Data.fromJSON(vectors["data"])
    #Consensus.
    consensus: Consensus = Consensus(
        bytes.fromhex("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"),
        bytes.fromhex("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"),
    )
    sv: SignedVerification = SignedVerification.fromJSON(vectors["verification"])
    consensus.add(sv)
    #Blockchain.
    blockchain: Blockchain = Blockchain.fromJSON(
        b"MEROS_DEVELOPER_NETWORK",
        60,
        int("FAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", 16),
        vectors["blockchain"]
    )
    file.close()

    #Handshake with the node.
    rpc.meros.connect(
        254,
        254,
        len(blockchain.blocks)
    )

    sentLast: bool = False
    hash: bytes = bytes()
    while True:
        msg: bytes = rpc.meros.recv()

        if MessageType(msg[0]) == MessageType.Syncing:
            rpc.meros.acknowledgeSyncing()

        elif MessageType(msg[0]) == MessageType.GetBlockHash:
            height: int = int.from_bytes(msg[1 : 5], byteorder = "big")
            if height == 0:
                rpc.meros.blockHash(blockchain.last())
            else:
                if height >= len(blockchain.blocks):
                    raise TestError("Meros asked for a Block Hash we do not have.")

                rpc.meros.blockHash(blockchain.blocks[height].header.hash)

        elif MessageType(msg[0]) == MessageType.BlockHeaderRequest:
            hash = msg[1 : 49]
            for block in blockchain.blocks:
                if block.header.hash == hash:
                    rpc.meros.blockHeader(block.header)
                    break

                if block.header.hash == blockchain.last():
                    raise TestError("Meros asked for a Block Header we do not have.")

        elif MessageType(msg[0]) == MessageType.BlockBodyRequest:
            hash = msg[1 : 49]
            for block in blockchain.blocks:
                if block.header.hash == hash:
                    rpc.meros.blockBody(block.body)
                    break

                if block.header.hash == blockchain.last():
                    raise TestError("Meros asked for a Block Body we do not have.")

        elif MessageType(msg[0]) == MessageType.ElementRequest:
            rpc.meros.element(sv)

        elif MessageType(msg[0]) == MessageType.TransactionRequest:
            sentLast = True
            rpc.meros.transaction(data)

        elif MessageType(msg[0]) == MessageType.SyncingOver:
            if sentLast:
                break

        else:
            raise TestError("Unexpected message sent: " + msg.hex().upper())

    #Verify the Blockchain.
    verifyBlockchain(rpc, blockchain)

    #Verify the Consensus.
    verifyConsensus(rpc, consensus)

    #Playback their messages.
    rpc.meros.playback()
