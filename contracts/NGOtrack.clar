(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-unauthorized-portfolio (err u104))
(define-constant err-project-not-found (err u105))
(define-constant err-invalid-rating (err u106))
(define-constant err-duplicate-project (err u107))
(define-constant err-insufficient-funds (err u108))
(define-constant err-invalid-donation-amount (err u109))
(define-constant err-donation-not-found (err u110))
(define-constant err-unauthorized-withdrawal (err u111))
(define-constant err-invalid-allocation (err u112))

(define-data-var next-id uint u1)
(define-data-var next-project-id uint u1)
(define-data-var next-donation-id uint u1)

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

(define-map ngo-portfolio
    uint
    {
        total-projects: uint,
        active-projects: uint,
        completed-projects: uint,
        total-budget: uint,
        funds-utilized: uint,
        impact-score: uint,
        beneficiaries-served: uint,
        last-updated: uint
    }
)

(define-map project-registry
    uint
    {
        ngo-id: uint,
        title: (string-ascii 100),
        description: (string-ascii 200),
        category: (string-ascii 50),
        budget: uint,
        spent: uint,
        status: (string-ascii 20),
        start-date: uint,
        end-date: uint,
        beneficiaries: uint,
        location: (string-ascii 100),
        created-by: principal,
        created-at: uint
    }
)

(define-map project-performance
    uint
    {
        efficiency-rating: uint,
        impact-rating: uint,
        transparency-rating: uint,
        completion-percentage: uint,
        stakeholder-ratings: uint,
        total-ratings: uint,
        last-reviewed: uint
    }
)

(define-map ngo-projects
    { ngo-id: uint, project-id: uint }
    bool
)

(define-map donation-registry
    uint
    {
        donor: principal,
        ngo-id: uint,
        project-id: (optional uint),
        amount: uint,
        donation-type: (string-ascii 20),
        message: (string-ascii 200),
        timestamp: uint,
        status: (string-ascii 20)
    }
)

(define-map ngo-fund-balance
    uint
    {
        total-received: uint,
        total-allocated: uint,
        available-balance: uint,
        total-withdrawn: uint,
        last-updated: uint
    }
)

(define-map project-funding
    uint
    {
        allocated-amount: uint,
        received-donations: uint,
        withdrawn-amount: uint,
        funding-status: (string-ascii 20),
        last-funding-update: uint
    }
)

(define-map donor-history
    principal
    {
        total-donated: uint,
        donation-count: uint,
        first-donation: uint,
        last-donation: uint,
        preferred-ngos: (list 5 uint)
    }
)

(define-map fund-allocations
    { ngo-id: uint, allocation-id: uint }
    {
        project-id: (optional uint),
        amount: uint,
        purpose: (string-ascii 100),
        allocated-by: principal,
        allocation-date: uint,
        status: (string-ascii 20)
    }
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

(define-read-only (get-ngo-portfolio (ngo-id uint))
    (match (map-get? ngo-portfolio ngo-id)
        portfolio-data (ok portfolio-data)
        (err err-not-found)
    )
)

(define-read-only (get-project-details (project-id uint))
    (match (map-get? project-registry project-id)
        project-data (ok project-data)
        (err err-project-not-found)
    )
)

(define-read-only (get-project-performance (project-id uint))
    (match (map-get? project-performance project-id)
        performance-data (ok performance-data)
        (err err-project-not-found)
    )
)

(define-read-only (check-ngo-project-link (ngo-id uint) (project-id uint))
    (default-to false (map-get? ngo-projects { ngo-id: ngo-id, project-id: project-id }))
)

(define-public (create-project
    (ngo-id uint)
    (title (string-ascii 100))
    (description (string-ascii 200))
    (category (string-ascii 50))
    (budget uint)
    (start-date uint)
    (end-date uint)
    (beneficiaries uint)
    (location (string-ascii 100)))
    
    (let ((project-id (var-get next-project-id)))
        (asserts! (is-some (map-get? ngo-registry ngo-id)) (err err-not-found))
        (asserts! (is-eq tx-sender (get registered-by (unwrap! (map-get? ngo-registry ngo-id) (err err-not-found)))) (err err-unauthorized-portfolio))
        (asserts! (is-none (map-get? ngo-projects { ngo-id: ngo-id, project-id: project-id })) (err err-duplicate-project))
        
        (map-set project-registry project-id {
            ngo-id: ngo-id,
            title: title,
            description: description,
            category: category,
            budget: budget,
            spent: u0,
            status: "active",
            start-date: start-date,
            end-date: end-date,
            beneficiaries: beneficiaries,
            location: location,
            created-by: tx-sender,
            created-at: stacks-block-height
        })
        
        (map-set project-performance project-id {
            efficiency-rating: u0,
            impact-rating: u0,
            transparency-rating: u0,
            completion-percentage: u0,
            stakeholder-ratings: u0,
            total-ratings: u0,
            last-reviewed: stacks-block-height
        })
        
        (map-set ngo-projects { ngo-id: ngo-id, project-id: project-id } true)
        (var-set next-project-id (+ project-id u1))
        (ok project-id)
    )
)

(define-public (update-project-spending (project-id uint) (amount uint))
    (let ((project-data (unwrap! (map-get? project-registry project-id) (err err-project-not-found))))
        (asserts! (is-eq tx-sender (get created-by project-data)) (err err-unauthorized-portfolio))
        (asserts! (<= (+ (get spent project-data) amount) (get budget project-data)) (err err-invalid-status))
        
        (map-set project-registry project-id 
            (merge project-data { spent: (+ (get spent project-data) amount) }))
        (ok true)
    )
)

(define-public (complete-project (project-id uint))
    (let ((project-data (unwrap! (map-get? project-registry project-id) (err err-project-not-found))))
        (asserts! (is-eq tx-sender (get created-by project-data)) (err err-unauthorized-portfolio))
        (asserts! (is-eq (get status project-data) "active") (err err-invalid-status))
        
        (map-set project-registry project-id 
            (merge project-data { status: "completed" }))
        
        (let ((performance-data (unwrap! (map-get? project-performance project-id) (err err-project-not-found))))
            (map-set project-performance project-id 
                (merge performance-data { 
                    completion-percentage: u100,
                    last-reviewed: stacks-block-height 
                }))
        )
        (ok true)
    )
)

(define-public (rate-project-performance 
    (project-id uint) 
    (efficiency uint) 
    (impact uint) 
    (transparency uint))
    
    (let ((project-data (unwrap! (map-get? project-registry project-id) (err err-project-not-found)))
          (performance-data (unwrap! (map-get? project-performance project-id) (err err-project-not-found))))
        
        (asserts! (and (>= efficiency u1) (<= efficiency u5)) (err err-invalid-rating))
        (asserts! (and (>= impact u1) (<= impact u5)) (err err-invalid-rating))
        (asserts! (and (>= transparency u1) (<= transparency u5)) (err err-invalid-rating))
        
        (let ((current-ratings (get total-ratings performance-data))
              (new-efficiency (/ (+ (* (get efficiency-rating performance-data) current-ratings) efficiency) (+ current-ratings u1)))
              (new-impact (/ (+ (* (get impact-rating performance-data) current-ratings) impact) (+ current-ratings u1)))
              (new-transparency (/ (+ (* (get transparency-rating performance-data) current-ratings) transparency) (+ current-ratings u1))))
            
            (map-set project-performance project-id {
                efficiency-rating: new-efficiency,
                impact-rating: new-impact,
                transparency-rating: new-transparency,
                completion-percentage: (get completion-percentage performance-data),
                stakeholder-ratings: (+ (* (get stakeholder-ratings performance-data) current-ratings) efficiency impact transparency),
                total-ratings: (+ current-ratings u1),
                last-reviewed: stacks-block-height
            })
            (ok true)
        )
    )
)

(define-private (update-ngo-portfolio-stats (ngo-id uint))
    (let ((current-portfolio (default-to 
            {
                total-projects: u0,
                active-projects: u0,
                completed-projects: u0,
                total-budget: u0,
                funds-utilized: u0,
                impact-score: u0,
                beneficiaries-served: u0,
                last-updated: u0
            }
            (map-get? ngo-portfolio ngo-id))))
        
        (let ((stats (calculate-portfolio-stats ngo-id)))
            (map-set ngo-portfolio ngo-id 
                (merge current-portfolio {
                    total-projects: (get total-projects stats),
                    active-projects: (get active-projects stats),
                    completed-projects: (get completed-projects stats),
                    total-budget: (get total-budget stats),
                    funds-utilized: (get funds-utilized stats),
                    impact-score: (get impact-score stats),
                    beneficiaries-served: (get beneficiaries-served stats),
                    last-updated: stacks-block-height
                }))
            (ok true)
        )
    )
)

(define-private (calculate-portfolio-stats (ngo-id uint))
    (fold aggregate-project-stats (get-project-ids-for-ngo ngo-id) {
        total-projects: u0,
        active-projects: u0,
        completed-projects: u0,
        total-budget: u0,
        funds-utilized: u0,
        impact-score: u0,
        beneficiaries-served: u0
    })
)

(define-private (aggregate-project-stats (project-id uint) (acc {
    total-projects: uint,
    active-projects: uint,
    completed-projects: uint,
    total-budget: uint,
    funds-utilized: uint,
    impact-score: uint,
    beneficiaries-served: uint
}))
    (match (map-get? project-registry project-id)
        project-data 
        (let ((performance-data (default-to 
                {
                    efficiency-rating: u0,
                    impact-rating: u0,
                    transparency-rating: u0,
                    completion-percentage: u0,
                    stakeholder-ratings: u0,
                    total-ratings: u0,
                    last-reviewed: u0
                }
                (map-get? project-performance project-id))))
            {
                total-projects: (+ (get total-projects acc) u1),
                active-projects: (+ (get active-projects acc) (if (is-eq (get status project-data) "active") u1 u0)),
                completed-projects: (+ (get completed-projects acc) (if (is-eq (get status project-data) "completed") u1 u0)),
                total-budget: (+ (get total-budget acc) (get budget project-data)),
                funds-utilized: (+ (get funds-utilized acc) (get spent project-data)),
                impact-score: (+ (get impact-score acc) (get impact-rating performance-data)),
                beneficiaries-served: (+ (get beneficiaries-served acc) (get beneficiaries project-data))
            })
        acc
    )
)

(define-private (get-project-ids-for-ngo (ngo-id uint))
    (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
)

(define-read-only (get-donation-details (donation-id uint))
    (match (map-get? donation-registry donation-id)
        donation-data (ok donation-data)
        (err err-donation-not-found)
    )
)

(define-read-only (get-ngo-fund-balance (ngo-id uint))
    (match (map-get? ngo-fund-balance ngo-id)
        balance-data (ok balance-data)
        (err err-not-found)
    )
)

(define-read-only (get-project-funding (project-id uint))
    (match (map-get? project-funding project-id)
        funding-data (ok funding-data)
        (err err-project-not-found)
    )
)

(define-read-only (get-donor-history (donor principal))
    (match (map-get? donor-history donor)
        history-data (ok history-data)
        (err err-not-found)
    )
)

(define-public (donate-to-ngo 
    (ngo-id uint) 
    (amount uint) 
    (message (string-ascii 200)))
    
    (let ((donation-id (var-get next-donation-id)))
        (asserts! (> amount u0) (err err-invalid-donation-amount))
        (asserts! (is-some (map-get? ngo-registry ngo-id)) (err err-not-found))
        
        (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) (err err-insufficient-funds))
        
        (map-set donation-registry donation-id {
            donor: tx-sender,
            ngo-id: ngo-id,
            project-id: none,
            amount: amount,
            donation-type: "general",
            message: message,
            timestamp: stacks-block-height,
            status: "completed"
        })
        
        (update-ngo-balance ngo-id amount "received")
        (update-donor-history tx-sender amount ngo-id)
        (var-set next-donation-id (+ donation-id u1))
        (ok donation-id)
    )
)

(define-public (donate-to-project 
    (ngo-id uint) 
    (project-id uint) 
    (amount uint) 
    (message (string-ascii 200)))
    
    (let ((donation-id (var-get next-donation-id)))
        (asserts! (> amount u0) (err err-invalid-donation-amount))
        (asserts! (is-some (map-get? ngo-registry ngo-id)) (err err-not-found))
        (asserts! (is-some (map-get? project-registry project-id)) (err err-project-not-found))
        (asserts! (check-ngo-project-link ngo-id project-id) (err err-invalid-allocation))
        
        (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) (err err-insufficient-funds))
        
        (map-set donation-registry donation-id {
            donor: tx-sender,
            ngo-id: ngo-id,
            project-id: (some project-id),
            amount: amount,
            donation-type: "project",
            message: message,
            timestamp: stacks-block-height,
            status: "completed"
        })
        
        (update-ngo-balance ngo-id amount "received")
        (update-project-funding project-id amount "received")
        (update-donor-history tx-sender amount ngo-id)
        (var-set next-donation-id (+ donation-id u1))
        (ok donation-id)
    )
)

(define-public (allocate-funds 
    (ngo-id uint) 
    (project-id (optional uint)) 
    (amount uint) 
    (purpose (string-ascii 100)))
    
    (let ((ngo-data (unwrap! (map-get? ngo-registry ngo-id) (err err-not-found)))
          (balance-data (default-to {
              total-received: u0,
              total-allocated: u0,
              available-balance: u0,
              total-withdrawn: u0,
              last-updated: u0
          } (map-get? ngo-fund-balance ngo-id))))
        
        (asserts! (is-eq tx-sender (get registered-by ngo-data)) (err err-unauthorized-withdrawal))
        (asserts! (>= (get available-balance balance-data) amount) (err err-insufficient-funds))
        
        (match project-id
            pid (begin
                (asserts! (is-some (map-get? project-registry pid)) (err err-project-not-found))
                (asserts! (check-ngo-project-link ngo-id pid) (err err-invalid-allocation))
                (update-project-funding pid amount "allocated")
            )
            true
        )
        
        (update-ngo-balance ngo-id amount "allocated")
        (ok true)
    )
)

(define-public (withdraw-funds 
    (ngo-id uint) 
    (amount uint) 
    (recipient principal))
    
    (let ((ngo-data (unwrap! (map-get? ngo-registry ngo-id) (err err-not-found)))
          (balance-data (default-to {
              total-received: u0,
              total-allocated: u0,
              available-balance: u0,
              total-withdrawn: u0,
              last-updated: u0
          } (map-get? ngo-fund-balance ngo-id))))
        
        (asserts! (is-eq tx-sender (get registered-by ngo-data)) (err err-unauthorized-withdrawal))
        (asserts! (>= (get available-balance balance-data) amount) (err err-insufficient-funds))
        (asserts! (is-eq (get status ngo-data) "verified") (err err-invalid-status))
        
        (unwrap! (as-contract (stx-transfer? amount tx-sender recipient)) (err err-insufficient-funds))
        (update-ngo-balance ngo-id amount "withdrawn")
        (ok true)
    )
)

(define-private (update-ngo-balance (ngo-id uint) (amount uint) (operation (string-ascii 20)))
    (let ((current-balance (default-to {
            total-received: u0,
            total-allocated: u0,
            available-balance: u0,
            total-withdrawn: u0,
            last-updated: u0
        } (map-get? ngo-fund-balance ngo-id))))
        
        (map-set ngo-fund-balance ngo-id 
            (if (is-eq operation "received")
                {
                    total-received: (+ (get total-received current-balance) amount),
                    total-allocated: (get total-allocated current-balance),
                    available-balance: (+ (get available-balance current-balance) amount),
                    total-withdrawn: (get total-withdrawn current-balance),
                    last-updated: stacks-block-height
                }
                (if (is-eq operation "allocated")
                    {
                        total-received: (get total-received current-balance),
                        total-allocated: (+ (get total-allocated current-balance) amount),
                        available-balance: (- (get available-balance current-balance) amount),
                        total-withdrawn: (get total-withdrawn current-balance),
                        last-updated: stacks-block-height
                    }
                    {
                        total-received: (get total-received current-balance),
                        total-allocated: (get total-allocated current-balance),
                        available-balance: (- (get available-balance current-balance) amount),
                        total-withdrawn: (+ (get total-withdrawn current-balance) amount),
                        last-updated: stacks-block-height
                    }
                )
            )
        )
    )
)

(define-private (update-project-funding (project-id uint) (amount uint) (operation (string-ascii 20)))
    (let ((current-funding (default-to {
            allocated-amount: u0,
            received-donations: u0,
            withdrawn-amount: u0,
            funding-status: "unfunded",
            last-funding-update: u0
        } (map-get? project-funding project-id))))
        
        (map-set project-funding project-id 
            (if (is-eq operation "received")
                {
                    allocated-amount: (get allocated-amount current-funding),
                    received-donations: (+ (get received-donations current-funding) amount),
                    withdrawn-amount: (get withdrawn-amount current-funding),
                    funding-status: "funded",
                    last-funding-update: stacks-block-height
                }
                {
                    allocated-amount: (+ (get allocated-amount current-funding) amount),
                    received-donations: (get received-donations current-funding),
                    withdrawn-amount: (get withdrawn-amount current-funding),
                    funding-status: "allocated",
                    last-funding-update: stacks-block-height
                }
            )
        )
    )
)

(define-private (update-donor-history (donor principal) (amount uint) (ngo-id uint))
    (let ((current-history (default-to {
            total-donated: u0,
            donation-count: u0,
            first-donation: stacks-block-height,
            last-donation: u0,
            preferred-ngos: (list)
        } (map-get? donor-history donor))))
        
        (map-set donor-history donor {
            total-donated: (+ (get total-donated current-history) amount),
            donation-count: (+ (get donation-count current-history) u1),
            first-donation: (if (is-eq (get donation-count current-history) u0) 
                stacks-block-height 
                (get first-donation current-history)),
            last-donation: stacks-block-height,
            preferred-ngos: (unwrap-panic (as-max-len? 
                (append (get preferred-ngos current-history) ngo-id) u5))
        })
    )
)

(define-read-only (get-total-donations-for-ngo (ngo-id uint))
    (match (map-get? ngo-fund-balance ngo-id)
        balance-data (ok (get total-received balance-data))
        (ok u0)
    )
)

(define-read-only (get-funding-transparency-report (ngo-id uint))
    (match (map-get? ngo-fund-balance ngo-id)
        balance-data (ok {
            total-received: (get total-received balance-data),
            total-allocated: (get total-allocated balance-data),
            available-balance: (get available-balance balance-data),
            total-withdrawn: (get total-withdrawn balance-data),
            utilization-rate: (if (> (get total-received balance-data) u0)
                (/ (* (get total-allocated balance-data) u100) (get total-received balance-data))
                u0),
            transparency-score: (calculate-transparency-score ngo-id)
        })
        (err err-not-found)
    )
)

(define-private (calculate-transparency-score (ngo-id uint))
    (let ((balance-data (default-to {
            total-received: u0,
            total-allocated: u0,
            available-balance: u0,
            total-withdrawn: u0,
            last-updated: u0
        } (map-get? ngo-fund-balance ngo-id))))
        
        (if (> (get total-received balance-data) u0)
            (+ 
                (if (> (get total-allocated balance-data) u0) u25 u0)
                (if (> (get total-withdrawn balance-data) u0) u25 u0)
                (if (< (/ (* (get available-balance balance-data) u100) (get total-received balance-data)) u80) u25 u0)
                u25
            )
            u0
        )
    )
)


