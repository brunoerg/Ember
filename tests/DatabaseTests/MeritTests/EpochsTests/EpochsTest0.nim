discard """
Epochs Test 0. Verifies that No Verifications = No Rewards.
"""

#Util lib.
import ../../../../src/lib/Util

#Hash lib.
import ../../../../src/lib/Hash

#Verifications lib.
import ../../../../src/Database/Verifications/Verifications

#Blockchain lib.
import ../../../../src/Database/Merit/Blockchain

#State lib.
import ../../../../src/Database/Merit/State

#Epochs lib.
import ../../../../src/Database/Merit/Epochs

#Merit Testing functions.
import ../TestMerit

var
    #Database Function Box.
    functions: DatabaseFunctionBox = newTestDatabase()
    #Verifications.
    verifications: Verifications = newVerifications(functions)
    #Blockchain.
    blockchain: Blockchain = newBlockchain(functions, "EPOCH_TEST_0", 1, "".pad(48).toHash(384))
    #State.
    state: State = newState(functions, 1)
    #Epochs.
    epochs: Epochs = newEpochs(functions, verifications, blockchain)
    #Rewards.
    rewards: Rewards = epochs.shift(
        verifications,
        @[]
    ).calculate(state)

assert(rewards.len == 0)

echo "Finished the Database/Merit/Epochs Test #0."
