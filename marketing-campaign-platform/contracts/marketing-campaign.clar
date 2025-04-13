;; marketing-campaign.clar
;; Marketing Campaign Platform Smart Contract

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_INVALID_AMOUNT u2)
(define-constant ERR_CAMPAIGN_NOT_FOUND u3)
(define-constant ERR_BENCHMARK_NOT_MET u4)

;; Data structures
(define-map campaigns
  { campaign-id: uint }
  {
    owner: principal,
    budget: uint,
    spent: uint,
    benchmarks: {
      impressions: uint,
      clicks: uint,
      conversions: uint
    },
    status: (string-ascii 20)
  }
)

(define-map campaign-metrics
  { campaign-id: uint }
  {
    impressions: uint,
    clicks: uint,
    conversions: uint
  }
)

;; Campaign counter for generating unique IDs
(define-data-var next-campaign-id uint u1)

;; Functions
(define-public (create-campaign (budget uint) (impression-goal uint) (click-goal uint) (conversion-goal uint))
  (let
    (
      (campaign-id (var-get next-campaign-id))
    )
    ;; Update campaign counter
    (var-set next-campaign-id (+ campaign-id u1))
    
    ;; Create campaign
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        owner: tx-sender,
        budget: budget,
        spent: u0,
        benchmarks: {
          impressions: impression-goal,
          clicks: click-goal,
          conversions: conversion-goal
        },
        status: "active"
      }
    )
    
    ;; Initialize metrics
    (map-set campaign-metrics
      { campaign-id: campaign-id }
      {
        impressions: u0,
        clicks: u0,
        conversions: u0
      }
    )
    
    (ok campaign-id)
  )
)

;; Update campaign metrics (restricted to authorized parties)
(define-public (update-metrics (campaign-id uint) (impressions uint) (clicks uint) (conversions uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (current-metrics (unwrap! (map-get? campaign-metrics { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
    )
    
    ;; Update metrics
    (map-set campaign-metrics
      { campaign-id: campaign-id }
      {
        impressions: (+ (get impressions current-metrics) impressions),
        clicks: (+ (get clicks current-metrics) clicks),
        conversions: (+ (get conversions current-metrics) conversions)
      }
    )
    
    (ok true)
  )
)

;; Process rewards based on performance
(define-public (process-rewards (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (metrics (unwrap! (map-get? campaign-metrics { campaign-id: campaign-id }) (err ERR_CAMPAIGN_NOT_FOUND)))
      (benchmarks (get benchmarks campaign))
    )
    
    ;; Check if benchmarks are met
    (if (and
          (>= (get impressions metrics) (get impressions benchmarks))
          (>= (get clicks metrics) (get clicks benchmarks))
          (>= (get conversions metrics) (get conversions benchmarks)))
        (begin
          ;; Distribute rewards logic would go here
          ;; For MVP, simply mark campaign as successful
          (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { status: "completed" })
          )
          (ok true)
        )
        (err ERR_BENCHMARK_NOT_MET)
    )
  )
)

;; Read-only functions
(define-read-only (get-campaign-details (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-campaign-metrics (campaign-id uint))
  (map-get? campaign-metrics { campaign-id: campaign-id })
)
