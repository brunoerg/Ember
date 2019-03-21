#Errors lib.
import ../../lib/Errors

#Util lib.
import ../../lib/Util

#Hash lib.
import ../../lib/Hash

#BLS lib.
import ../../lib/BLS

#Verifications objects.
import ../Verifications/Verifications

#DB Function Box object.
import ../../objects/GlobalFunctionBoxObj

#VerifierIndex object.
import objects/VerifierIndexObj

#State object.
import objects/StateObj

#Epoch objects.
import objects/EpochsObj
export EpochsObj

#Finals lib.
import finals

#Seq utils standard lib.
import sequtils

#Algorithm standard lib.
import algorithm

#Tables standard lib.
import tables

#Calculate what share each person deserves of the minted Meros.
proc calculate*(
    epoch: Epoch,
    state: State
): Rewards {.raises: [
    KeyError,
    FinalAttributeError
].} =
    #If the epoch is empty, do nothing.
    if epoch.len == 0:
        return @[]

    var
        #Score of a person. This is their combined normalized Entry values.
        scores: TableRef[string, uint] = newTable[string, uint]()
        #Total Merit behind an Entry.
        total: uint

    #Iterate over each Entry.
    for entry in epoch.keys():
        #Clear the loop variables.
        #We use result as a loop variable because we don't need it till later.
        result = newRewards()
        total = 0

        #Iterate over the result who verified an entry.
        for person in epoch[entry]:
            #Add them to our seq with their Merit.
            result.add(
                newReward(
                    person.toString(),
                    state[person]
                )
            )
            #Add the Merit to the total.
            total += result[^1].score

        #Make sure the Entry was verified.
        if total < ((state.live div uint(2)) + 1):
            #If it wasn't, move on.
            continue

        #Normalize each person to a share of 1000.
        for person in result:
            #Make sure they have a score.
            if not scores.hasKey(person.key):
                scores[person.key] = 0

            #Add this to their score.
            scores[person.key] += person.score * 1000 div total

    #Turn the table into a seq.
    #Here's where we clear result and actually put in the data that will be returned.
    result = newRewards()
    for key in scores.keys():
        result.add(
            newReward(
                key,
                scores[key]
            )
        )

    #Make sure we're dealing with a maximum of 100 results.
    if epoch.len > 100:
        #Sort them by greatest score.
        result.sort(
            proc (
                x: Reward,
                y: Reward
            ): int =
                if x.score > y.score:
                    result = 1
                elif x.score == y.score:
                    result = 0
                else:
                    result = -1
            , SortOrder.Descending
        )

        #Declare the cutoff edge.
        var edge: int = 100
        #If the result at the edge are tied...
        while result[edge-1].score == result[edge].score:
            #Increase the edge.
            inc(edge)

        #Delete everything after the edge.
        result.delete(edge, result.len-1)

    #Reuse total to calculate the total score.
    total = 0
    for person in result:
        total += person.score

    #Normalize each person to a score of 1000.
    for i in 0 ..< result.len:
        result[i].score = result[i].score * 1000 div total

#This shift does four things:
# - Adds the newest set of Verifications.
# - Stores the oldest Epoch to be returned.
# - Removes the oldest Epoch from Epochs.
# - Saves the VerifierIndexes in the Epoch to-be-returned to the Database.
#If tips is provided, which it is when loading from the DB, those are used instead of verifier.archived.
proc shift*(
    epochs: Epochs,
    verifs: Verifications,
    indexes: seq[VerifierIndex],
    tips: TableRef[string, int] = nil
): Epoch {.raises: [
    KeyError,
    ValueError,
    BLSError,
    LMDBError,
    FinalAttributeError
].} =
    var
        #New Epoch for any Verifications belonging to Entries that aren't in an older Epoch.
        newEpoch: Epoch = newEpoch(indexes)
        #Loop variable saying if we found the Entry in an older Epoch.
        found: bool
        #Loop variable of what verification to start with.
        start: int

    #Loop over each Verification.
    for index in indexes:
        #If we were passed tips, use those for the starting point.
        if not tips.isNil:
            start = tips[index.key]
        #Else, use the verifier's archived.
        else:
            start = verifs[index.key].archived

        #Iterate over every Verification.
        for verif in verifs[index.key][start .. int(index.nonce)]:
            #Set found to false.
            found = false

            #Try adding this hash to an existing Epoch.
            if epochs.add(verif.hash.toString(), verif.verifier):
                found = true

            #If it wasn't in an existing Epoch, add it to the new Epoch.
            if not found:
                newEpoch.add(verif.hash.toString(), verif.verifier)

        #If we were passed a set of tips, update them.
        if not tips.isNil:
            tips[index.key] = int(index.nonce)

    #Return the popped Epoch.
    result = epochs.shift(newEpoch, indexes, tips.isNil)
