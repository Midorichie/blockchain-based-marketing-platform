;; marketing-campaign.clar
;; Marketing Campaign Platform Smart Contract - Enhanced Version

;; Import the provider trait from ad-provider contract
(use-trait provider-trait .ad-provider.provider-trait)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_INVALID_AMOUNT u2)
(define-constant ERR_CAMPAIGN_NOT_FOUND u3)
(define-constant ERR_BENCHMARK_NOT_MET u4)
(define-constant ERR_INSUFFICIENT_FUNDS u5)
(define-constant ERR_INACTIVE_PROVIDER u6)
(define-constant ERR_CAMPAIGN_INACTIVE u7)
(define-constant ERR_LIST_OVERFLOW u100)

;; Data structures
(define-map campaigns
  { campaign-id: uint }
  {
    owner: principal,
    budget: uint,
    spent: uint,
    remaining: uint,
    benchmarks: {
      impressions: uint,
      clicks: uint,
      conversions: uint
    },
    status: (string-ascii 20),
    providers: (list 10 principal),
    creation-time: uint,
    expiration-time: uint
  }
)

(define-map campaign-metrics
  { campaign-id: uint }
  {
    impressions: uint,
    clicks: uint,
    conversions: uint,
    last-updated: uint
  }
)

;; Campaign counter for generating unique IDs
(define-data-var next-campaign-id uint u1)

;; Contract admin/owner - for enhanced security
(define-data-var admin-contract principal tx-sender)

;; Contract for verifying ad providers
(define-data-var provider-contract-address (optional principal) none)

;; Time-based constants (in blocks)
(define-constant DEFAULT_EXPIRATION_PERIOD u10080) ;; ~70 days assuming 10-minute blocks

;; Enhanced Functions

;; Set the provider contract address
(define-public (set-provider-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-contract)) (err ERR_UNAUTHORIZED))
    (var-set provider-contract-address (some new-contract))
    (ok true)
  )
)

;; Create campaign with STX budget
(define-public (create-campaign (budget uint) (impression-goal uint) (click-goal uint) (conversion-goal uint) (duration uint))
  (let
    (
      (campaign-id (var-get next-campaign-id))
      (actual-duration (if (> duration u0) duration DEFAULT_EXPIRATION_PERIOD))
      (expiration-time (+ block-height actual-duration))
    )
    ;; Check sufficient funds
    (asserts! (>= (stx-get-balance tx-sender) budget) (err ERR_INSUFFICIENT_FUNDS))
    
    ;; Transfer STX to contract for escrow
    (try! (stx-transfer? budget tx-sender (as-contract tx-sender)))
    
    ;; Update campaign counter
    (var-set next-campaign-id (+ campaign-id u1))
    
    ;; Create campaign with fuller details
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        owner: tx-sender,
        budget: budget,
        spent: u0,
        remaining: budget,
        benchmarks: {
          impressions: impression-goal,
          clicks: click-goal,
          conversions: conversion-goal
        },
        status: "active",
        providers: (list),
        creation-time: block-height,
        expiration-time: expiration-time
      }
    )
    
    ;; Initialize metrics with timestamp
    (map-set campaign-metrics
      { campaign-id: campaign-id }
      {
        impressions: u0,
        clicks: u0,
        conversions: u0,
        last-updated: block-height
      }
    )
    
    (ok campaign-id)
  )
)

;; Add authorized provider to campaign
(define-public (add-campaign-provider (campaign-id uint) (provider-trait-contract <provider-trait>) (provider principal))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (provider-status (try! (contract-call? provider-trait-contract is-active-provider provider)))
    )
    ;; Only campaign owner can add providers
    (asserts! (is-eq tx-sender (get owner campaign)) (err ERR_UNAUTHORIZED))
    
    ;; Check if provider is active using the provider contract
    (asserts! provider-status (err ERR_INACTIVE_PROVIDER))
    
    ;; Add provider to campaign's list of authorized providers
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign 
        { providers: (unwrap! (as-max-len? (append (get providers campaign) provider) u10) 
                             (err ERR_LIST_OVERFLOW)) }
      )
    )
    
    (ok true)
  )
)

;; Update campaign metrics (restricted to authorized providers or campaign owner)
(define-public (update-metrics (campaign-id uint) (impressions uint) (clicks uint) (conversions uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (current-metrics (unwrap! (map-get? campaign-metrics { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (provider-contract-opt (var-get provider-contract-address))
      (is-authorized-provider (is-some (index-of (get providers campaign) tx-sender)))
      (is-campaign-owner (is-eq tx-sender (get owner campaign)))
    )
    
    ;; Check campaign is active
    (asserts! (is-eq (get status campaign) "active") (err ERR_CAMPAIGN_INACTIVE))
    
    ;; Check authorization - must be owner or authorized provider
    (asserts! 
      (or 
        is-campaign-owner
        is-authorized-provider
        (match provider-contract-opt
          contract-address (match (contract-call? contract-address is-active-provider tx-sender)
                             success (and (is-ok success) (unwrap! (unwrap-panic success) false))
                             error false)
          false)
      ) 
      (err ERR_UNAUTHORIZED)
    )
    
    ;; Update metrics with timestamp
    (map-set campaign-metrics
      { campaign-id: campaign-id }
      {
        impressions: (+ (get impressions current-metrics) impressions),
        clicks: (+ (get clicks current-metrics) clicks),
        conversions: (+ (get conversions current-metrics) conversions),
        last-updated: block-height
      }
    )
    
    (ok true)
  )
)

;; Process rewards based on performance with actual STX transfer
(define-public (process-rewards (campaign-id uint) (recipient principal))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (metrics (unwrap! (map-get? campaign-metrics { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (benchmarks (get benchmarks campaign))
      (remaining-budget (get remaining campaign))
    )
    ;; Authorization check - only owner or admin contract can process rewards
    (asserts! (or 
                (is-eq tx-sender (get owner campaign)) 
                (is-eq tx-sender (var-get admin-contract))
              ) 
              (err ERR_UNAUTHORIZED))
    
    ;; Check if campaign is active
    (asserts! (is-eq (get status campaign) "active") (err ERR_CAMPAIGN_INACTIVE))
    
    ;; Check if benchmarks are met
    (if (and
          (>= (get impressions metrics) (get impressions benchmarks))
          (>= (get clicks metrics) (get clicks benchmarks))
          (>= (get conversions metrics) (get conversions benchmarks)))
        (begin
          ;; Transfer STX reward from contract to recipient
          (try! (as-contract (stx-transfer? remaining-budget tx-sender recipient)))
          
          ;; Update campaign status and budget
          (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { 
              status: "completed",
              spent: (get budget campaign),
              remaining: u0
            })
          )
          
          (ok true)
        )
        (err ERR_BENCHMARK_NOT_MET)
    )
  )
)

;; Cancel campaign and refund remaining budget
(define-public (cancel-campaign (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (remaining-budget (get remaining campaign))
    )
    ;; Only campaign owner can cancel
    (asserts! (is-eq tx-sender (get owner campaign)) (err ERR_UNAUTHORIZED))
    
    ;; Check if campaign is active
    (asserts! (is-eq (get status campaign) "active") (err ERR_CAMPAIGN_INACTIVE))
    
    ;; Transfer remaining STX back to owner
    (try! (as-contract (stx-transfer? remaining-budget tx-sender (get owner campaign))))
    
    ;; Update campaign status
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { 
        status: "cancelled",
        remaining: u0
      })
    )
    
    (ok true)
  )
)

;; Check and expire campaigns that have passed their expiration date
(define-public (check-campaign-expiration (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
    )
    ;; Check if campaign is active and expired
    (if (and 
          (is-eq (get status campaign) "active")
          (> block-height (get expiration-time campaign)))
        (begin
          ;; Return remaining funds to owner
          (try! (as-contract (stx-transfer? (get remaining campaign) tx-sender (get owner campaign))))
          
          ;; Update campaign status
          (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { 
              status: "expired",
              remaining: u0
            })
          )
          
          (ok true)
        )
        (ok false)
    )
  )
)

;; Transfer contract ownership
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-contract)) (err ERR_UNAUTHORIZED))
    (var-set admin-contract new-admin)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-campaign-details (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-campaign-metrics (campaign-id uint))
  (map-get? campaign-metrics { campaign-id: campaign-id })
)

(define-read-only (is-provider-authorized (campaign-id uint) (provider principal))
  (let
    (
      (campaign (unwrap-panic (map-get? campaigns { campaign-id: campaign-id })))
    )
    (is-some (index-of (get providers campaign) provider))
  )
)
