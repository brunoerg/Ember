#Errors lib.
import ../../lib/Errors

#Util lib.
import ../../lib/Util

#Hash lib.
import ../../lib/Hash

#MinerWallet lib.
import ../../Wallet/MinerWallet

#Wallet libs.
import ../../Wallet/Address
import ../../Wallet/Wallet

#Entry object and descendants.
import objects/EntryObj
import objects/MintObj
import objects/ClaimObj
import objects/SendObj
import objects/ReceiveObj
import objects/DataObj

#Account object.
import objects/AccountObj
export AccountObj

#Add a Mint.
proc add*(
    account: Account,
    mint: Mint
) {.forceCheck: [
    ValueError,
    IndexError,
    GapError,
    EdPublicKeyError,
    DataExists
].} =
    try:
        account.add(cast[Entry](mint))
    except ValueError as e:
        fcRaise e
    except IndexError as e:
        fcRaise e
    except GapError as e:
        fcRaise e
    except EdPublicKeyError as e:
        fcRaise e
    except DataExists as e:
        fcRaise e

#Add a Claim.
proc add*(
    account: Account,
    claim: Claim,
    mint: Mint
) {.forceCheck: [
    ValueError,
    IndexError,
    GapError,
    EdPublicKeyError,
    BLSError,
    DataExists
].} =
    #Verify the BLS signature is for this mint and this person.
    try:
        claim.bls.setAggregationInfo(
            newBLSAggregationInfo(
                mint.output,
                "claim" & mint.nonce.toBinary() & Address.toPublicKey(account.address)
            )
        )
        if not claim.bls.verify():
            raise newException(ValueError, "Claim had invalid BLS signature.")
    except AddressError:
        doAssert(false, "Created an account with an invalid address.")
    except BLSError as e:
        fcRaise e

    #Verify it's unclaimed.

    #Add the Claim.
    try:
        account.add(cast[Entry](claim))
    except ValueError as e:
        fcRaise e
    except IndexError as e:
        fcRaise e
    except GapError as e:
        fcRaise e
    except EdPublicKeyError as e:
        fcRaise e
    except DataExists as e:
        fcRaise e

#Add a Send.
proc add*(
    account: Account,
    send: Send,
    difficulty: Hash[384]
) {.forceCheck: [
    ValueError,
    IndexError,
    GapError,
    EdPublicKeyError,
    DataExists
].} =
    #Verify the work.
    if send.argon <= difficulty:
        raise newException(ValueError, "Failed to verify the Send's work.")

    #Verify the output is a valid address.
    if not Address.isValid(send.output):
        raise newException(ValueError, "Failed to verify the Send's output.")

    #Verify the account has enough money.
    if account.balance < send.amount:
        raise newException(ValueError, "Sender doesn't have enough monery for this Send.")

    #Add the Send.
    try:
        account.add(cast[Entry](send))
    except ValueError as e:
        fcRaise e
    except IndexError as e:
        fcRaise e
    except GapError as e:
        fcRaise e
    except EdPublicKeyError as e:
        fcRaise e
    except DataExists as e:
        fcRaise e

#Add a Receive.
proc add*(
    account: Account,
    recv: Receive,
    sendArg: Entry
) {.forceCheck: [
    ValueError,
    IndexError,
    GapError,
    EdPublicKeyError,
    DataExists
].} =
    #Verify the entry is a Send.
    if sendArg.descendant != EntryType.Send:
        raise newException(ValueError, "Trying to Receive from an Entry that isn't a Send.")

    #Cast it to a Send.
    var send: Send = cast[Send](sendArg)

    #Verify the Send's output address.
    if account.address != send.output:
        raise newException(ValueError, "Receiver is trying to receive from a Send which isn't for them.")

    #Verify it's unclaimed.

    #Add the Receive.
    try:
        account.add(cast[Entry](recv))
    except ValueError as e:
        fcRaise e
    except IndexError as e:
        fcRaise e
    except GapError as e:
        fcRaise e
    except EdPublicKeyError as e:
        fcRaise e
    except DataExists as e:
        fcRaise e

#Add Data.
proc add*(
    account: Account,
    data: Data,
    difficulty: Hash[384]
) {.forceCheck: [
    ValueError,
    IndexError,
    GapError,
    EdPublicKeyError,
    DataExists
].} =
    #Verify the work.
    if data.argon <= difficulty:
        raise newException(ValueError, "Failed to verify the Data's work.")

    #Add the Data.
    try:
        account.add(cast[Entry](data))
    except ValueError as e:
        fcRaise e
    except IndexError as e:
        fcRaise e
    except GapError as e:
        fcRaise e
    except EdPublicKeyError as e:
        fcRaise e
    except DataExists as e:
        fcRaise e
