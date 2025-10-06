;; Title: TimeLock Proof
;; A Bitcoin-secured message attestation protocol for provable communication integrity
;;
;; Summary:
;; TimeLock Proof creates immutable proof-of-existence records for encrypted communications
;; by anchoring cryptographic hashes to Bitcoin through Stacks. Messages remain private 
;; off-chain while their integrity and timestamp inherit Bitcoin's finality guarantees.
;;
;; Description:
;; Built for scenarios demanding cryptographic proof without content exposure-legal 
;; agreements, compliance documentation, confidential negotiations. Users submit SHA-256 
;; hashes of encrypted messages, receiving block-height timestamps and non-repudiation 
;; guarantees. Third-party verification happens on-chain without revealing message contents.
;; Perfect for whistleblowing, intellectual property claims, or any high-stakes communication 
;; requiring tamper-evident audit trails backed by Bitcoin's security model.

;; ========================================
;; CONSTANTS & ERROR CODES
;; ========================================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ZERO-ADDRESS 'SP000000000000000000002Q6VF78)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-MESSAGE (err u101))
(define-constant ERR-MESSAGE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-HASH (err u103))
(define-constant ERR-INVALID-RECIPIENT (err u104))

;; ========================================
;; DATA STORAGE
;; ========================================

;; State variables
(define-data-var total-messages uint u0)
(define-data-var contract-version uint u1)

;; Message records with full metadata
(define-map messages
  { message-id: uint }
  {
    sender: principal,
    recipient: principal,
    message-hash: (buff 32),
    timestamp: uint,
    block-height: uint,
    verified: bool
  }
)

;; Per-user message counters
(define-map user-message-count
  { user: principal }
  { count: uint }
)

;; Hash verification tracking
(define-map message-verification
  { message-hash: (buff 32) }
  { 
    message-id: uint,
    verification-count: uint
  }
)

;; ========================================
;; PRIVATE HELPERS
;; ========================================

(define-private (is-valid-hash (hash (buff 32)))
  (> (len hash) u0)
)

(define-private (is-valid-principal (user principal))
  (not (is-eq user ZERO-ADDRESS))
)

(define-private (increment-user-count (user principal))
  (let ((current-count (default-to u0 (get count (map-get? user-message-count { user: user })))))
    (map-set user-message-count 
      { user: user }
      { count: (+ current-count u1) }
    )
  )
)

;; ========================================
;; CORE PROTOCOL FUNCTIONS
;; ========================================

;; Anchor message hash to Bitcoin via Stacks
;; @param recipient: Message destination principal
;; @param message-hash: SHA-256 hash of encrypted message (32 bytes)
;; @returns Message ID on success
(define-public (send-message (recipient principal) (message-hash (buff 32)))
  (let 
    (
      (message-id (+ (var-get total-messages) u1))
      (current-block stacks-block-height)
    )
    ;; Input validation
    (asserts! (is-valid-principal recipient) ERR-INVALID-RECIPIENT)
    (asserts! (is-valid-hash message-hash) ERR-INVALID-HASH)
    (asserts! (not (is-eq tx-sender recipient)) ERR-UNAUTHORIZED)
    
    ;; Store message record
    (map-set messages
      { message-id: message-id }
      {
        sender: tx-sender,
        recipient: recipient,
        message-hash: message-hash,
        timestamp: current-block,
        block-height: current-block,
        verified: false
      }
    )
    
    ;; Initialize verification data
    (map-set message-verification
      { message-hash: message-hash }
      {
        message-id: message-id,
        verification-count: u1
      }
    )
    
    ;; Update state
    (var-set total-messages message-id)
    (increment-user-count tx-sender)
    
    (ok message-id)
  )
)

;; Verify message integrity against blockchain record
;; @param message-id: Target message identifier
;; @param provided-hash: Hash to validate
;; @returns True if hash matches stored record
(define-public (verify-message (message-id uint) (provided-hash (buff 32)))
  (let 
    (
      (message-data (unwrap! (map-get? messages { message-id: message-id }) ERR-MESSAGE-NOT-FOUND))
      (stored-hash (get message-hash message-data))
    )
    (asserts! (is-valid-hash provided-hash) ERR-INVALID-HASH)
    (asserts! (> message-id u0) ERR-INVALID-MESSAGE)
    
    (if (is-eq stored-hash provided-hash)
      (begin
        ;; Mark verified
        (map-set messages
          { message-id: message-id }
          (merge message-data { verified: true })
        )
        
        ;; Increment verification counter
        (let ((current-verification (default-to { message-id: u0, verification-count: u0 } 
                                               (map-get? message-verification { message-hash: provided-hash }))))
          (map-set message-verification
            { message-hash: provided-hash }
            {
              message-id: message-id,
              verification-count: (+ (get verification-count current-verification) u1)
            }
          )
        )
        (ok true)
      )
      (ok false)
    )
  )
)

;; ========================================
;; READ-ONLY QUERY FUNCTIONS
;; ========================================

;; Retrieve complete message record
;; @param message-id: Message identifier
;; @returns Full message metadata or none
(define-read-only (get-message-info (message-id uint))
  (begin
    (asserts! (> message-id u0) ERR-INVALID-MESSAGE)
    (ok (map-get? messages { message-id: message-id }))
  )
)

;; Get total messages for a user
;; @param user: Principal to query
;; @returns Message count
(define-read-only (get-user-message-count (user principal))
  (begin
    (asserts! (is-valid-principal user) ERR-INVALID-RECIPIENT)
    (ok (default-to u0 (get count (map-get? user-message-count { user: user }))))
  )
)

;; Get global message counter
;; @returns Total protocol messages
(define-read-only (get-total-messages)
  (ok (var-get total-messages))
)

;; Get current contract version
;; @returns Version identifier
(define-read-only (get-contract-version)
  (ok (var-get contract-version))
)

;; Check if hash exists on-chain
;; @param hash: SHA-256 hash to search
;; @returns True if hash is registered
(define-read-only (message-hash-exists (hash (buff 32)))
  (begin
    (asserts! (is-valid-hash hash) ERR-INVALID-HASH)
    (ok (is-some (map-get? message-verification { message-hash: hash })))
  )
)

;; Get verification count for hash
;; @param hash: Message hash
;; @returns Total verification attempts
(define-read-only (get-verification-count (hash (buff 32)))
  (begin
    (asserts! (is-valid-hash hash) ERR-INVALID-HASH)
    (ok (default-to u0 (get verification-count (map-get? message-verification { message-hash: hash }))))
  )
)

;; ========================================
;; ADMIN FUNCTIONS
;; ========================================

;; Update contract version (owner only)
;; @param new-version: Version number
;; @returns Success status
(define-public (update-contract-version (new-version uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (> new-version (var-get contract-version)) ERR-INVALID-MESSAGE)
    (var-set contract-version new-version)
    (ok true)
  )
)