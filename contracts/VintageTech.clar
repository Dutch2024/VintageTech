;; VintageTech: Collectible Electronics Marketplace
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-ITEM-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-LISTED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-YEAR (err u5))
(define-constant ERR-INVALID-CATEGORY (err u6))
(define-constant ERR-INVALID-CONDITION (err u7))
(define-constant ERR-INVALID-NAME (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))
(define-constant MIN-YEAR u1950)
(define-data-var next-item-id uint u1)
(define-map collectible-items
    uint
    {
        collector: principal,
        item-name: (string-utf8 50),
        description: (string-utf8 200),
        category: (string-utf8 15),
        condition: (string-utf8 15),
        status: (string-utf8 10),
        manufacture-year: uint
    }
)
(define-private (validate-category (category (string-utf8 15)))
    (or 
        (is-eq category u"Computer")
        (is-eq category u"Audio")
        (is-eq category u"Gaming")
        (is-eq category u"Photography")
        (is-eq category u"Television")
        (is-eq category u"Radio")
    )
)
(define-private (validate-condition (condition (string-utf8 15)))
    (or 
        (is-eq condition u"Mint")
        (is-eq condition u"Excellent")
        (is-eq condition u"Good")
        (is-eq condition u"Fair")
        (is-eq condition u"For Parts")
    )
)
(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (register-item 
    (item-name (string-utf8 50))
    (description (string-utf8 200))
    (category (string-utf8 15))
    (condition (string-utf8 15))
    (manufacture-year uint)
)
    (let
        (
            (item-id (var-get next-item-id))
        )
        (asserts! (validate-text-length item-name u3 u50) ERR-INVALID-NAME)
        (asserts! (validate-text-length description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= manufacture-year MIN-YEAR) ERR-INVALID-YEAR)
        (asserts! (validate-category category) ERR-INVALID-CATEGORY)
        (asserts! (validate-condition condition) ERR-INVALID-CONDITION)
        
        (map-set collectible-items item-id {
            collector: tx-sender,
            item-name: item-name,
            description: description,
            category: category,
            condition: condition,
            status: u"available",
            manufacture-year: manufacture-year
        })
        (var-set next-item-id (+ item-id u1))
        (ok item-id)
    )
)
(define-public (delist-item (item-id uint))
    (let
        (
            (item (unwrap! (map-get? collectible-items item-id) ERR-ITEM-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get collector item)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status item) u"available") ERR-INVALID-STATUS)
        (ok (map-set collectible-items item-id (merge item { status: u"unlisted" })))
    )
)
(define-read-only (get-item (item-id uint))
    (ok (map-get? collectible-items item-id))
)
(define-read-only (get-collector (item-id uint))
    (ok (get collector (unwrap! (map-get? collectible-items item-id) ERR-ITEM-NOT-FOUND)))
)