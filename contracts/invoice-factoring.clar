;; Invoice Factoring Platform Smart Contract
;; Enables small businesses to sell outstanding invoices to investors for immediate cash flow

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u1000))
(define-constant err-invoice-not-found (err u1001))
(define-constant err-invalid-amount (err u1002))
(define-constant err-invoice-already-exists (err u1003))
(define-constant err-offer-not-found (err u1004))
(define-constant err-insufficient-funds (err u1005))
(define-constant err-invoice-not-pending (err u1006))
(define-constant err-offer-expired (err u1007))
(define-constant err-unauthorized-action (err u1008))
(define-constant err-invoice-already-paid (err u1009))
(define-constant err-invalid-buyer (err u1010))

;; Invoice Status Constants
(define-constant status-pending u0)
(define-constant status-factored u1)
(define-constant status-paid u2)
(define-constant status-disputed u3)

;; Data Variables
(define-data-var next-invoice-id uint u1)
(define-data-var next-offer-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points

;; Data Maps
(define-map invoices
  { invoice-id: uint }
  {
    seller: principal,
    buyer: principal,
    amount: uint,
    due-date: uint,
    status: uint,
    created-at: uint,
    description: (string-ascii 256),
    factored-amount: uint,
    investor: (optional principal)
  }
)

(define-map factoring-offers
  { offer-id: uint }
  {
    invoice-id: uint,
    investor: principal,
    discount-rate: uint, ;; in basis points (e.g., 500 = 5%)
    offered-amount: uint,
    expires-at: uint,
    is-accepted: bool
  }
)

(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map buyer-verification
  { buyer: principal }
  {
    credit-score: uint,
    verified-at: uint,
    is-verified: bool
  }
)

(define-map invoice-offers-count
  { invoice-id: uint }
  { count: uint }
)

;; Private Functions
(define-private (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

(define-private (set-balance (user principal) (amount uint))
  (map-set user-balances { user: user } { balance: amount })
)

(define-private (calculate-factored-amount (amount uint) (discount-rate uint))
  (let ((discount (/ (* amount discount-rate) u10000)))
    (- amount discount)
  )
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

(define-private (is-invoice-owner (invoice-id uint) (user principal))
  (match (map-get? invoices { invoice-id: invoice-id })
    invoice (is-eq (get seller invoice) user)
    false
  )
)

(define-private (is-offer-owner (offer-id uint) (user principal))
  (match (map-get? factoring-offers { offer-id: offer-id })
    offer (is-eq (get investor offer) user)
    false
  )
)

;; Public Functions

;; Submit a new invoice for factoring
(define-public (submit-invoice (buyer principal) (amount uint) (due-date uint) (description (string-ascii 256)))
  (let (
    (invoice-id (var-get next-invoice-id))
    (current-height block-height)
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> due-date current-height) err-invalid-amount)
    (asserts! (not (is-eq buyer tx-sender)) err-invalid-buyer)
    
    (map-set invoices
      { invoice-id: invoice-id }
      {
        seller: tx-sender,
        buyer: buyer,
        amount: amount,
        due-date: due-date,
        status: status-pending,
        created-at: current-height,
        description: description,
        factored-amount: u0,
        investor: none
      }
    )
    
    (map-set invoice-offers-count
      { invoice-id: invoice-id }
      { count: u0 }
    )
    
    (var-set next-invoice-id (+ invoice-id u1))
    (ok invoice-id)
  )
)

;; Verify buyer creditworthiness
(define-public (verify-buyer (buyer principal) (credit-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (and (>= credit-score u300) (<= credit-score u850)) err-invalid-amount)
    
    (map-set buyer-verification
      { buyer: buyer }
      {
        credit-score: credit-score,
        verified-at: block-height,
        is-verified: true
      }
    )
    
    (ok true)
  )
)

;; Submit a factoring offer for an invoice
(define-public (submit-factoring-offer (invoice-id uint) (discount-rate uint) (expires-in-blocks uint))
  (let (
    (offer-id (var-get next-offer-id))
    (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) err-invoice-not-found))
    (offered-amount (calculate-factored-amount (get amount invoice) discount-rate))
    (current-height block-height)
    (expires-at (+ current-height expires-in-blocks))
    (current-count (default-to u0 (get count (map-get? invoice-offers-count { invoice-id: invoice-id }))))
  )
    (asserts! (is-eq (get status invoice) status-pending) err-invoice-not-pending)
    (asserts! (and (>= discount-rate u100) (<= discount-rate u5000)) err-invalid-amount) ;; 1%-50% discount
    (asserts! (> expires-in-blocks u0) err-invalid-amount)
    (asserts! (>= (get-balance tx-sender) offered-amount) err-insufficient-funds)
    
    (map-set factoring-offers
      { offer-id: offer-id }
      {
        invoice-id: invoice-id,
        investor: tx-sender,
        discount-rate: discount-rate,
        offered-amount: offered-amount,
        expires-at: expires-at,
        is-accepted: false
      }
    )
    
    (map-set invoice-offers-count
      { invoice-id: invoice-id }
      { count: (+ current-count u1) }
    )
    
    (var-set next-offer-id (+ offer-id u1))
    (ok offer-id)
  )
)

;; Accept a factoring offer
(define-public (accept-factoring-offer (offer-id uint))
  (let (
    (offer (unwrap! (map-get? factoring-offers { offer-id: offer-id }) err-offer-not-found))
    (invoice-id (get invoice-id offer))
    (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) err-invoice-not-found))
    (investor (get investor offer))
    (offered-amount (get offered-amount offer))
    (platform-fee (calculate-platform-fee offered-amount))
    (seller-amount (- offered-amount platform-fee))
  )
    (asserts! (is-invoice-owner invoice-id tx-sender) err-unauthorized-action)
    (asserts! (is-eq (get status invoice) status-pending) err-invoice-not-pending)
    (asserts! (< block-height (get expires-at offer)) err-offer-expired)
    (asserts! (not (get is-accepted offer)) err-unauthorized-action)
    (asserts! (>= (get-balance investor) offered-amount) err-insufficient-funds)
    
    ;; Update offer as accepted
    (map-set factoring-offers
      { offer-id: offer-id }
      (merge offer { is-accepted: true })
    )
    
    ;; Update invoice as factored
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice {
        status: status-factored,
        factored-amount: offered-amount,
        investor: (some investor)
      })
    )
    
    ;; Transfer funds
    (set-balance investor (- (get-balance investor) offered-amount))
    (set-balance tx-sender (+ (get-balance tx-sender) seller-amount))
    (set-balance contract-owner (+ (get-balance contract-owner) platform-fee))
    
    (ok true)
  )
)

;; Mark invoice as paid (called by buyer or contract owner)
(define-public (mark-invoice-paid (invoice-id uint))
  (let (
    (invoice (unwrap! (map-get? invoices { invoice-id: invoice-id }) err-invoice-not-found))
    (investor (unwrap! (get investor invoice) err-unauthorized-action))
    (original-amount (get amount invoice))
  )
    (asserts! (or (is-eq tx-sender (get buyer invoice)) (is-eq tx-sender contract-owner)) err-unauthorized-action)
    (asserts! (is-eq (get status invoice) status-factored) err-invoice-not-pending)
    
    ;; Update invoice status
    (map-set invoices
      { invoice-id: invoice-id }
      (merge invoice { status: status-paid })
    )
    
    ;; Pay investor the full invoice amount
    (set-balance investor (+ (get-balance investor) original-amount))
    
    (ok true)
  )
)

;; Withdraw funds from contract
(define-public (withdraw-funds (amount uint))
  (let ((user-balance (get-balance tx-sender)))
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= user-balance amount) err-insufficient-funds)
    
    (set-balance tx-sender (- user-balance amount))
    (as-contract (stx-transfer? amount tx-sender tx-sender))
  )
)

;; Deposit funds to contract
(define-public (deposit-funds (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) err-insufficient-funds)
    (set-balance tx-sender (+ (get-balance tx-sender) amount))
    (ok true)
  )
)

;; Read-only functions

;; Get invoice details
(define-read-only (get-invoice-details (invoice-id uint))
  (map-get? invoices { invoice-id: invoice-id })
)

;; Get factoring offer details
(define-read-only (get-factoring-offer (offer-id uint))
  (map-get? factoring-offers { offer-id: offer-id })
)

;; Get user balance
(define-read-only (get-user-balance (user principal))
  (get-balance user)
)

;; Get buyer verification status
(define-read-only (get-buyer-verification (buyer principal))
  (map-get? buyer-verification { buyer: buyer })
)

;; Calculate factoring amount
(define-read-only (calculate-factoring-amount (amount uint) (discount-rate uint))
  (calculate-factored-amount amount discount-rate)
)

;; Get invoice offers count
(define-read-only (get-invoice-offers-count (invoice-id uint))
  (default-to u0 (get count (map-get? invoice-offers-count { invoice-id: invoice-id })))
)

;; Get platform fee rate
(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

;; Get next invoice ID
(define-read-only (get-next-invoice-id)
  (var-get next-invoice-id)
)

;; Get next offer ID
(define-read-only (get-next-offer-id)
  (var-get next-offer-id)
)

;; Check if user is invoice owner
(define-read-only (is-user-invoice-owner (invoice-id uint) (user principal))
  (is-invoice-owner invoice-id user)
)


;; title: invoice-factoring
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

