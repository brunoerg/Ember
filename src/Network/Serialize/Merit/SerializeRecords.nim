#MeritHolderRecord is under common, yet serialized in a Block. Therefore, it's under Serialize/Merit.

#Errors lib.
import ../../../lib/Errors

#Util lib.
import ../../../lib/Util

#Hash lib.
import ../../../lib/Hash

#MinerWallet lib.
import ../../../Wallet/MinerWallet

#MeritHolderRecord object.
import ../../../Database/common/objects/MeritHolderRecordObj

#Common serialization functions.
import ../SerializeCommon

#Serialize Records.
proc serialize*(
    records: seq[MeritHolderRecord]
): string {.forceCheck: [].} =
    #Set the quantity.
    result = records.len.toBinary().pad(INT_LEN)

    #Iterate over every MeritHolderRecord.
    for record in records:
        #Serialize their data.
        result &=
            record.key.toString() &
            record.nonce.toBinary().pad(INT_LEN) &
            record.merkle.toString()
