(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-status (err u103))

(define-data-var next-id uint u1)

(define-map ngo-registry 
    uint 
    {
        name: (string-ascii 50),
        registration-number: (string-ascii 20),
        country: (string-ascii 50),
        founding-year: uint,
        website: (string-ascii 100),
        contact: (string-ascii 100),
        status: (string-ascii 20),
        registered-by: principal,
        registration-date: uint
    }
)

(define-map address-to-ngo 
    principal 
    uint
)

(define-read-only (get-ngo-details (id uint))
    (match (map-get? ngo-registry id)
        ngo-data (ok ngo-data)
        (err err-not-found)
    )
)

(define-read-only (get-ngo-by-address (address principal))
    (match (map-get? address-to-ngo address)
        id (get-ngo-details id)
        (err err-not-found)
    )
)

(define-read-only (is-verified (id uint))
    (match (map-get? ngo-registry id)
        ngo-data (ok (is-eq (get status ngo-data) "verified"))
        (err err-not-found)
    )
)

(define-public (register-ngo 
    (name (string-ascii 50))
    (registration-number (string-ascii 20))
    (country (string-ascii 50))
    (founding-year uint)
    (website (string-ascii 100))
    (contact (string-ascii 100)))
    
    (let ((id (var-get next-id)))
        (asserts! (is-none (map-get? address-to-ngo tx-sender)) (err err-already-registered))
        
        (map-set ngo-registry id {
            name: name,
            registration-number: registration-number,
            country: country,
            founding-year: founding-year,
            website: website,
            contact: contact,
            status: "pending",
            registered-by: tx-sender,
            registration-date: stacks-block-height
        })
        
        (map-set address-to-ngo tx-sender id)
        (var-set next-id (+ id u1))
        (ok id)
    )
)

(define-public (verify-ngo (id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
        (match (map-get? ngo-registry id)
            ngo-data 
            (begin
                (map-set ngo-registry id 
                    (merge ngo-data { status: "verified" }))
                (ok true))
            (err err-not-found)
        )
    )
)

(define-public (reject-ngo (id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
        (match (map-get? ngo-registry id)
            ngo-data 
            (begin
                (map-set ngo-registry id 
                    (merge ngo-data { status: "rejected" }))
                (ok true))
            (err err-not-found)
        )
    )
)

(define-public (suspend-ngo (id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
        (match (map-get? ngo-registry id)
            ngo-data 
            (begin
                (map-set ngo-registry id 
                    (merge ngo-data { status: "suspended" }))
                (ok true))
            (err err-not-found)
        )
    )
)

;; (define-read-only (get-all-ngos-by-status (status (string-ascii 20)))
;;     (filter (check-status-match status) (map uint-to-ngo-tuple (get-ngo-ids)))
;; )

(define-private (check-status-match (status (string-ascii 20)) (ngo-tuple {id: uint, data: (optional {
    name: (string-ascii 50),
    registration-number: (string-ascii 20),
    country: (string-ascii 50),
    founding-year: uint,
    website: (string-ascii 100),
    contact: (string-ascii 100),
    status: (string-ascii 20),
    registered-by: principal,
    registration-date: uint
})}))
    (match (get data ngo-tuple)
        data (is-eq (get status data) status)
        false
    )
)

(define-private (uint-to-ngo-tuple (id uint))
    {
        id: id,
        data: (map-get? ngo-registry id)
    }
)

(define-private (get-ngo-ids)
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)
)