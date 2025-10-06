# 🕒 TimeLock Proof

**A Bitcoin-secured message attestation protocol for provable communication integrity.**

---

## Overview

**TimeLock Proof** provides an immutable verification layer for encrypted communications without revealing message content.
By anchoring message hashes to Bitcoin through the **Stacks blockchain**, it enables cryptographic proof of existence, timestamping, and tamper-evident verification for any digital correspondence.

Built for **high-assurance communication**, TimeLock Proof ensures that message integrity and timing can be independently verified on-chain while preserving complete off-chain confidentiality.

---

## Key Features

* **Bitcoin-backed finality:** Proofs inherit Bitcoin’s settlement guarantees via Stacks anchoring.
* **Privacy-preserving:** Only message hashes are recorded — the encrypted content never touches the blockchain.
* **Non-repudiation:** Each message attestation links a sender, recipient, and timestamp.
* **Verification transparency:** Anyone can confirm a message’s existence and integrity without access to the message body.
* **Tamper-evident:** Once anchored, proofs are immutable and auditable indefinitely.
* **Lightweight design:** Optimized Clarity contract with deterministic validation logic.

---

## System Overview

| Component                   | Role                   | Description                                                                    |
| --------------------------- | ---------------------- | ------------------------------------------------------------------------------ |
| **Client Layer**            | Off-chain applications | Generates encrypted messages and their SHA-256 hashes before submission.       |
| **TimeLock Proof Contract** | On-chain registry      | Anchors message hashes with timestamps, principals, and verification metadata. |
| **Stacks Blockchain**       | Execution layer        | Processes Clarity smart contract logic deterministically.                      |
| **Bitcoin Blockchain**      | Settlement layer       | Anchors Stacks state roots, providing final immutability guarantees.           |

**Data Flow Summary:**

1. A user encrypts a message off-chain and computes its SHA-256 hash.
2. The hash and intended recipient are submitted to the `send-message` function.
3. The contract stores the hash, timestamp, and principals, returning a unique message ID.
4. Any verifier can later call `verify-message` with the same hash to confirm the message’s authenticity.
5. Verification counts and message status are tracked on-chain for auditability.

---

## Contract Architecture

### Core Modules

| Section                | Purpose                                                                         |
| ---------------------- | ------------------------------------------------------------------------------- |
| **Message Anchoring**  | Stores message hash, sender, recipient, and block metadata.                     |
| **Verification Logic** | Validates hashes and increments verification counters.                          |
| **Query Interface**    | Provides read-only functions for message metadata and verification counts.      |
| **Access Control**     | Restricts administrative actions (e.g., version updates) to the contract owner. |

---

### Data Structures

| Structure                  | Description                                                                      |
| -------------------------- | -------------------------------------------------------------------------------- |
| **`messages`**             | Maps message IDs to sender, recipient, hash, timestamp, and verification status. |
| **`message-verification`** | Tracks verification counts per message hash.                                     |
| **`user-message-count`**   | Maintains per-user submission counts.                                            |
| **`contract-version`**     | Tracks version upgrades for migration and compatibility.                         |

---

### Constants and Error Codes

| Constant                       | Meaning                                                |
| ------------------------------ | ------------------------------------------------------ |
| `ERR-UNAUTHORIZED (u100)`      | Action restricted to contract owner or invalid sender. |
| `ERR-INVALID-MESSAGE (u101)`   | Invalid message ID or format.                          |
| `ERR-MESSAGE-NOT-FOUND (u102)` | Message does not exist on-chain.                       |
| `ERR-INVALID-HASH (u103)`      | Submitted hash is malformed or empty.                  |
| `ERR-INVALID-RECIPIENT (u104)` | Recipient principal is invalid.                        |

---

## Public Functions

| Function                                        | Purpose                                                                             |
| ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| **`(send-message recipient message-hash)`**     | Anchors a new message hash with sender, recipient, and timestamp.                   |
| **`(verify-message message-id provided-hash)`** | Confirms a message hash matches the on-chain record and updates verification count. |
| **`(update-contract-version new-version)`**     | Owner-only function to manage version control.                                      |

---

## Read-Only Functions

| Function                     | Description                                             |
| ---------------------------- | ------------------------------------------------------- |
| **`get-message-info`**       | Retrieves full metadata for a message by ID.            |
| **`get-user-message-count`** | Returns the number of messages submitted by a user.     |
| **`get-total-messages`**     | Returns the total number of messages recorded globally. |
| **`get-contract-version`**   | Returns the active contract version.                    |
| **`message-hash-exists`**    | Checks if a given hash exists in the registry.          |
| **`get-verification-count`** | Returns how many times a hash has been verified.        |

---

## Example Flow

**1️⃣ Submit Proof**

```clarity
(contract-call? .timelock-proof send-message 
  'SP3FBR2AGK8N2QTV9R8W7H6SP1HKHJ3N8KX2T9Z9A 
  0x5feceb66ffc86f38d952786c6d696c79...)
```

**2️⃣ Verify Proof**

```clarity
(contract-call? .timelock-proof verify-message 
  u1 
  0x5feceb66ffc86f38d952786c6d696c79...)
```

**3️⃣ Query Record**

```clarity
(contract-call? .timelock-proof get-message-info u1)
```

---

## Security Model

* **Zero Knowledge by Design:** Only hashes are stored; message data remains fully off-chain.
* **Non-Repudiation:** Each proof is permanently tied to the sender’s principal and block height.
* **Bitcoin Finality:** Through Stacks’ anchoring mechanism, every proof inherits Bitcoin’s immutability guarantees.
* **Replay Resistance:** Message IDs are globally unique and sequentially managed on-chain.

---

## Potential Use Cases

* 🧾 **Legal and Compliance Proofs** — Timestamped digital agreements without revealing content.
* 🔒 **Confidential Negotiations** — Secure proof of communication timelines.
* 📢 **Whistleblower Submissions** — Anonymous attestations anchored to Bitcoin.
* 💡 **Intellectual Property Claims** — Verifiable ownership timestamp of original work.
* 🕵️‍♀️ **Forensic Data Provenance** — Cryptographic audit trails for secure data exchange.

---

## Deployment Notes

* **Contract Language:** [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview)
* **Network Compatibility:** Stacks Mainnet & Testnet
* **Dependencies:** None (self-contained)
* **Upgrade Policy:** Controlled via `update-contract-version` by `CONTRACT-OWNER`

---

## License

**MIT License**
Copyright ©
Permission is hereby granted, free of charge, to use, modify, and distribute this software under the terms of the MIT License.
