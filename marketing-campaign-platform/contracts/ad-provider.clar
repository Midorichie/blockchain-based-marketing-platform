;; ad-provider.clar
;; Contract to manage authorized ad providers who can update campaign metrics
 
;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_REGISTERED u3)
(define-constant ERR_INVALID_STATUS u4)
(define-constant ERR_INVALID_SCORE u5)
 
;; Data structures
(define-map providers
  { provider: principal }
  {
    name: (string-ascii 50),
    status: (string-ascii 10),
    trust-score: uint,
    registration-height: uint
  }
)
 
;; Contract owner
(define-data-var contract-owner principal tx-sender)
 
;; Provider count
(define-data-var provider-count uint u0)

;; Define provider trait for use by other contracts
(define-trait provider-trait
  (
    (is-active-provider (principal) (response bool uint))
  )
)
 
;; Administrative functions
(define-public (register-provider (provider principal) (name (string-ascii 50)))
  (begin
    ;; Only contract owner can register providers
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
  
    ;; Check if provider is already registered
    (asserts! (is-none (map-get? providers { provider: provider })) (err ERR_ALREADY_REGISTERED))
  
    ;; Register new provider
    (map-set providers
      { provider: provider }
      {
        name: name,
        status: "active",
        trust-score: u100,
        registration-height: block-height
      }
    )
  
    ;; Increment provider count
    (var-set provider-count (+ (var-get provider-count) u1))
  
    (ok true)
  )
)
 
(define-public (update-provider-status (provider principal) (new-status (string-ascii 10)))
  (begin
    ;; Only contract owner can update provider status
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
  
    ;; Check if provider exists
    (asserts! (is-some (map-get? providers { provider: provider })) (err ERR_NOT_REGISTERED))
  
    ;; Validate status (only accept "active" or "inactive")
    (asserts! (or (is-eq new-status "active") (is-eq new-status "inactive")) (err ERR_INVALID_STATUS))
  
    ;; Update provider status
    (let ((provider-data (unwrap! (map-get? providers { provider: provider }) (err ERR_NOT_REGISTERED))))
      (map-set providers
        { provider: provider }
        (merge provider-data { status: new-status })
      )
    )
  
    (ok true)
  )
)
 
(define-public (update-trust-score (provider principal) (score uint))
  (begin
    ;; Only contract owner can update trust scores
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
  
    ;; Check if provider exists
    (asserts! (is-some (map-get? providers { provider: provider })) (err ERR_NOT_REGISTERED))
  
    ;; Ensure score is between 0 and 100
    (asserts! (<= score u100) (err ERR_INVALID_SCORE))
  
    ;; Update provider trust score
    (let ((provider-data (unwrap! (map-get? providers { provider: provider }) (err ERR_NOT_REGISTERED))))
      (map-set providers
        { provider: provider }
        (merge provider-data { trust-score: score })
      )
    )
  
    (ok true)
  )
)
 
;; Read-only functions
(define-read-only (is-active-provider (provider principal))
  (match (map-get? providers { provider: provider })
    provider-data (ok (is-eq (get status provider-data) "active"))
    (err ERR_NOT_REGISTERED)
  )
)
 
(define-read-only (get-provider-details (provider principal))
  (map-get? providers { provider: provider })
)
 
(define-read-only (get-provider-count)
  (var-get provider-count)
)
 
;; Allow contract owner transfer
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
