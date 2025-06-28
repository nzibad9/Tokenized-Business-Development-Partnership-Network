;; Partnership Manager Verification Contract
;; Validates and manages business development managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-managers
  { manager: principal }
  {
    verified-at: uint,
    verification-level: uint,
    reputation-score: uint,
    active: bool
  }
)

(define-map manager-credentials
  { manager: principal }
  {
    company: (string-ascii 100),
    role: (string-ascii 50),
    experience-years: uint,
    certifications: (list 10 (string-ascii 50))
  }
)

(define-data-var total-verified-managers uint u0)

;; Public functions
(define-public (verify-manager (manager principal) (verification-level uint) (initial-reputation uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-managers { manager: manager })) ERR_ALREADY_VERIFIED)
    (asserts! (and (>= verification-level u1) (<= verification-level u5)) ERR_INVALID_CREDENTIALS)

    (map-set verified-managers
      { manager: manager }
      {
        verified-at: block-height,
        verification-level: verification-level,
        reputation-score: initial-reputation,
        active: true
      }
    )
    (var-set total-verified-managers (+ (var-get total-verified-managers) u1))
    (ok true)
  )
)

(define-public (update-manager-credentials
  (company (string-ascii 100))
  (role (string-ascii 50))
  (experience-years uint)
  (certifications (list 10 (string-ascii 50)))
)
  (begin
    (asserts! (is-some (map-get? verified-managers { manager: tx-sender })) ERR_NOT_FOUND)

    (map-set manager-credentials
      { manager: tx-sender }
      {
        company: company,
        role: role,
        experience-years: experience-years,
        certifications: certifications
      }
    )
    (ok true)
  )
)

(define-public (update-reputation (manager principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? verified-managers { manager: manager })
      manager-data (begin
        (map-set verified-managers
          { manager: manager }
          (merge manager-data { reputation-score: new-score })
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

;; Read-only functions
(define-read-only (is-verified-manager (manager principal))
  (match (map-get? verified-managers { manager: manager })
    manager-data (get active manager-data)
    false
  )
)

(define-read-only (get-manager-info (manager principal))
  (map-get? verified-managers { manager: manager })
)

(define-read-only (get-manager-credentials (manager principal))
  (map-get? manager-credentials { manager: manager })
)

(define-read-only (get-total-verified-managers)
  (var-get total-verified-managers)
)
