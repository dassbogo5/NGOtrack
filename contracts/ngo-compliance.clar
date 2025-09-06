;; NGO Compliance Reporting System
;; Allows verified NGOs to submit periodic compliance reports

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-report-type (err u201))
(define-constant err-report-not-found (err u202))
(define-constant err-not-verified-ngo (err u203))
(define-constant err-report-already-reviewed (err u204))
(define-constant err-empty-report-content (err u205))
(define-constant err-ngo-not-found (err u206))

;; Data variables
(define-data-var next-compliance-id uint u1)

;; Maps
(define-map compliance-reports
    uint
    {
        ngo-id: uint,
        report-type: (string-ascii 20),
        report-content: (string-ascii 500),
        document-hash: (optional (string-ascii 100)),
        submitted-at: uint,
        submitted-by: principal,
        status: (string-ascii 20),
        reviewed-at: (optional uint),
        reviewed-by: (optional principal),
        review-comments: (optional (string-ascii 300))
    }
)

(define-map ngo-reports
    uint
    (list 20 uint)
)

(define-map ngo-compliance-status
    uint
    {
        total-reports: uint,
        approved-reports: uint,
        rejected-reports: uint,
        pending-reports: uint,
        last-report-date: (optional uint),
        compliance-score: uint
    }
)

;; Read-only functions to interact with main NGOtrack contract
(define-read-only (is-ngo-verified (ngo-id uint))
    (contract-call? .NGOtrack is-verified ngo-id)
)

(define-read-only (get-ngo-by-principal (addr principal))
    (contract-call? .NGOtrack get-ngo-by-address addr)
)

;; Read-only functions
(define-read-only (get-compliance-report (report-id uint))
    (match (map-get? compliance-reports report-id)
        report-data (ok report-data)
        (err err-report-not-found)
    )
)

(define-read-only (get-ngo-compliance-status (ngo-id uint))
    (match (map-get? ngo-compliance-status ngo-id)
        status-data (ok status-data)
        (ok {
            total-reports: u0,
            approved-reports: u0,
            rejected-reports: u0,
            pending-reports: u0,
            last-report-date: none,
            compliance-score: u0
        })
    )
)

(define-read-only (get-ngo-reports (ngo-id uint))
    (default-to (list) (map-get? ngo-reports ngo-id))
)

(define-read-only (get-latest-report-id)
    (- (var-get next-compliance-id) u1)
)

;; Private functions
(define-private (is-valid-report-type (report-type (string-ascii 20)))
    (or 
        (is-eq report-type "financial")
        (or
            (is-eq report-type "activity")
            (or
                (is-eq report-type "governance")
                (is-eq report-type "impact")
            )
        )
    )
)

(define-private (calculate-compliance-score (ngo-id uint))
    (let ((status-data (unwrap-panic (get-ngo-compliance-status ngo-id))))
        (let ((total (get total-reports status-data))
              (approved (get approved-reports status-data)))
            (if (> total u0)
                (/ (* approved u100) total)
                u0
            )
        )
    )
)

(define-private (update-ngo-compliance-status (ngo-id uint) (new-status (string-ascii 20)))
    (let ((current-status (unwrap-panic (get-ngo-compliance-status ngo-id))))
        (let ((new-total (+ (get total-reports current-status) u1))
              (new-approved (if (is-eq new-status "approved") 
                              (+ (get approved-reports current-status) u1)
                              (get approved-reports current-status)))
              (new-rejected (if (is-eq new-status "rejected")
                              (+ (get rejected-reports current-status) u1)
                              (get rejected-reports current-status)))
              (new-pending (if (is-eq new-status "pending")
                             (+ (get pending-reports current-status) u1)
                             (if (is-eq new-status "approved")
                               (- (get pending-reports current-status) u1)
                               (- (get pending-reports current-status) u1)))))
            
            (map-set ngo-compliance-status ngo-id {
                total-reports: (if (is-eq new-status "pending") new-total (get total-reports current-status)),
                approved-reports: new-approved,
                rejected-reports: new-rejected,
                pending-reports: new-pending,
                last-report-date: (if (is-eq new-status "pending") 
                                    (some stacks-block-height)
                                    (get last-report-date current-status)),
                compliance-score: (calculate-compliance-score ngo-id)
            })
        )
    )
)

;; Public functions
(define-public (submit-compliance-report 
    (ngo-id uint)
    (report-type (string-ascii 20))
    (report-content (string-ascii 500))
    (document-hash (optional (string-ascii 100))))
    
    (let ((report-id (var-get next-compliance-id)))
        ;; Validations
        (asserts! (> (len report-content) u0) (err err-empty-report-content))
        (asserts! (is-valid-report-type report-type) (err err-invalid-report-type))
        
        ;; Check if NGO exists and sender is authorized
        (let ((ngo-data (unwrap! (contract-call? .NGOtrack get-ngo-details ngo-id) (err err-ngo-not-found))))
            (asserts! (is-eq tx-sender (get registered-by ngo-data)) (err err-not-verified-ngo))
        )
        
        ;; Check if NGO is verified
        (let ((verification-result (unwrap! (is-ngo-verified ngo-id) (err err-not-verified-ngo))))
            (asserts! verification-result (err err-not-verified-ngo))
        )
        
        ;; Create compliance report
        (map-set compliance-reports report-id {
            ngo-id: ngo-id,
            report-type: report-type,
            report-content: report-content,
            document-hash: document-hash,
            submitted-at: stacks-block-height,
            submitted-by: tx-sender,
            status: "pending",
            reviewed-at: none,
            reviewed-by: none,
            review-comments: none
        })
        
        ;; Add report to NGO's report list
        (let ((current-reports (get-ngo-reports ngo-id)))
            (map-set ngo-reports ngo-id 
                (unwrap-panic (as-max-len? (append current-reports report-id) u20)))
        )
        
        ;; Update NGO compliance status
        (update-ngo-compliance-status ngo-id "pending")
        
        ;; Increment next ID
        (var-set next-compliance-id (+ report-id u1))
        
        (ok report-id)
    )
)

(define-public (review-compliance-report 
    (report-id uint)
    (approve bool)
    (review-comments (optional (string-ascii 300))))
    
    (begin
        ;; Only contract owner can review
        (asserts! (is-eq tx-sender contract-owner) (err err-owner-only))
        
        ;; Get the report
        (match (map-get? compliance-reports report-id)
            report-data 
            (begin
                ;; Check if already reviewed
                (asserts! (is-eq (get status report-data) "pending") (err err-report-already-reviewed))
                
                ;; Update report with review
                (let ((new-status (if approve "approved" "rejected")))
                    (map-set compliance-reports report-id 
                        (merge report-data {
                            status: new-status,
                            reviewed-at: (some stacks-block-height),
                            reviewed-by: (some tx-sender),
                            review-comments: review-comments
                        })
                    )
                    
                    ;; Update NGO compliance status
                    (update-ngo-compliance-status (get ngo-id report-data) new-status)
                    
                    (ok true)
                )
            )
            (err err-report-not-found)
        )
    )
)

(define-public (get-ngo-compliance-summary (ngo-id uint))
    (let ((status-data (unwrap-panic (get-ngo-compliance-status ngo-id)))
          (reports (get-ngo-reports ngo-id)))
        (ok {
            ngo-id: ngo-id,
            total-reports: (get total-reports status-data),
            approved-reports: (get approved-reports status-data),
            rejected-reports: (get rejected-reports status-data),
            pending-reports: (get pending-reports status-data),
            compliance-score: (get compliance-score status-data),
            recent-reports: reports
        })
    )
)
