;; ReputationProtocol: Decentralized Reputation Scoring System
;; Version: 1.0.0

(define-data-var protocol-guardian principal tx-sender)
(define-data-var reputation-index uint u0)
(define-data-var trust-dividend uint u60) ;; trust points added per block
(define-data-var last-calculation uint u0) ;; last block when trust was calculated
(define-map entity-reputation principal uint)

;; Helper function to ensure only the protocol guardian can perform certain actions
(define-private (is-guardian (caller principal))
  (begin
    (asserts! (is-eq caller (var-get protocol-guardian)) (err u100))
    (ok true)))

;; Initialize the protocol
(define-public (activate (guardian principal))
  (begin
    (asserts! (is-none (map-get? entity-reputation guardian)) (err u101))
    (var-set protocol-guardian guardian)
    (ok "ReputationProtocol activated")))

;; Record positive reputation signals
(define-public (endorse (points uint))
  (begin
    (asserts! (> points u0) (err u102))
    (let ((current-reputation (default-to u0 (map-get? entity-reputation tx-sender))))
      (map-set entity-reputation tx-sender (+ current-reputation points))
      (var-set reputation-index (+ (var-get reputation-index) points))
      (ok (+ current-reputation points)))))

;; Calculate trust dividends across the network
(define-public (calculate-trust)
  (begin
    (try! (is-guardian tx-sender))
    (let ((current-block tenure-height)
          (previous-calculation (var-get last-calculation)))
      (asserts! (> current-block previous-calculation) (err u103))
      ;; Calculate trust based on blocks elapsed
      (let ((elapsed (- current-block previous-calculation))
            (total-trust (* elapsed (var-get trust-dividend))))
        (var-set last-calculation current-block)
        (var-set reputation-index (+ (var-get reputation-index) total-trust))
        (ok total-trust)))))

;; Leverage reputation for benefits
(define-public (leverage-reputation)
  (begin
    (let ((entity-trust (default-to u0 (map-get? entity-reputation tx-sender))))
      (asserts! (> entity-trust u0) (err u104))
      (let ((total-reputation (var-get reputation-index))
            (new-trust (* (var-get trust-dividend) (- tenure-height (var-get last-calculation))))
            (trust-ratio (/ (* entity-trust u100000) total-reputation)))
        ;; Calculate benefits based on trust ratio
        (let ((benefit-amount (/ (* trust-ratio new-trust) u100000)))
          (map-delete entity-reputation tx-sender)
          (var-set reputation-index (- (var-get reputation-index) entity-trust))
          (ok (+ entity-trust benefit-amount)))))))