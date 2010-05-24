;;;
;;; Copyright (c) 2010 uim Project http://code.google.com/p/uim/
;;;
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;; 1. Redistributions of source code must retain the above copyright
;;;    notice, this list of conditions and the following disclaimer.
;;; 2. Redistributions in binary form must reproduce the above copyright
;;;    notice, this list of conditions and the following disclaimer in the
;;;    documentation and/or other materials provided with the distribution.
;;; 3. Neither the name of authors nor the names of its contributors
;;;    may be used to endorse or promote products derived from this software
;;;    without specific prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
;;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
;;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;;

(require "util.scm")
(require "japanese.scm")
(require-custom "generic-key-custom.scm")
(require-custom "mozc-custom.scm")
(require-custom "mozc-key-custom.scm")

;;; implementations

(define mozc-type-direct          ja-type-direct)
(define mozc-type-hiragana        ja-type-hiragana)
(define mozc-type-katakana        ja-type-katakana)
(define mozc-type-halfkana        ja-type-halfkana)
(define mozc-type-halfwidth-alnum ja-type-halfwidth-alnum)
(define mozc-type-fullwidth-alnum ja-type-fullwidth-alnum)

(define mozc-prepare-input-mode-activation
  (lambda (mc new-mode)
    (mozc-lib-set-input-mode mc (mozc-context-mc-id mc) new-mode)))

(register-action 'action_mozc_hiragana
		 (lambda (mc) ;; indication handler
                   '(ja_hiragana
                      "あ"
                      "ひらがな"
                      "ひらがな入力モード"))
		 (lambda (mc) ;; activity predicate
                   (and
                     (mozc-context-on mc)
		     (= (mozc-lib-input-mode (mozc-context-mc-id mc)) mozc-type-hiragana)))
		 (lambda (mc) ;; action handler
                   (mozc-prepare-input-mode-activation mc mozc-type-hiragana)))

(register-action 'action_mozc_katakana
		 (lambda (mc)
                   '(ja_katakana
                      "ア"
                      "カタカナ"
                      "カタカナ入力モード"))
		 (lambda (mc)
                   (and
                     (mozc-context-on mc)
		     (= (mozc-lib-input-mode (mozc-context-mc-id mc)) mozc-type-katakana)))
		 (lambda (mc)
                   (mozc-prepare-input-mode-activation mc mozc-type-katakana)))

(register-action 'action_mozc_halfkana
		 (lambda (mc)
                   '(ja_halfkana
                      "ｱ"
                      "半角カタカナ"
                      "半角カタカナ入力モード"))
		 (lambda (mc)
                   (and
                     (mozc-context-on mc)
		     (= (mozc-lib-input-mode (mozc-context-mc-id mc)) mozc-type-halfkana)))
		 (lambda (mc)
                   (mozc-prepare-input-mode-activation mc mozc-type-halfkana)))

(register-action 'action_mozc_halfwidth_alnum
		 (lambda (mc)
                   '(ja_halfwidth_alnum
                      "a"
                      "半角英数"
                      "半角英数入力モード"))
		 (lambda (mc)
                   (and
                     (mozc-context-on mc)
		     (= (mozc-lib-input-mode (mozc-context-mc-id mc)) mozc-type-halfwidth-alnum)))
		 (lambda (mc)
                   (mozc-prepare-input-mode-activation mc mozc-type-halfwidth-alnum)))

(register-action 'action_mozc_direct
		 (lambda (mc)
                   '(ja_direct
                      "-"
                      "直接入力"
                      "直接(無変換)入力モード"))
		 (lambda (mc)
		   (not (mozc-context-on mc)))
		 (lambda (mc)
                   (mozc-prepare-input-mode-activation mc mozc-type-direct)))

(register-action 'action_mozc_fullwidth_alnum
		 (lambda (mc)
                   '(ja_fullwidth_alnum
                      "Ａ"
                      "全角英数"
                      "全角英数入力モード"))
		 (lambda (mc)
                   (and
                     (mozc-context-on mc)
                     (= (mozc-lib-input-mode (mozc-context-mc-id mc)) mozc-type-fullwidth-alnum)))
		 (lambda (mc)
                   (mozc-prepare-input-mode-activation mc mozc-type-fullwidth-alnum)))

;; Update widget definitions based on action configurations. The
;; procedure is needed for on-the-fly reconfiguration involving the
;; custom API
(define mozc-configure-widgets
  (lambda ()
    (register-widget 'widget_mozc_input_mode
		     (activity-indicator-new mozc-input-mode-actions)
		     (actions-new mozc-input-mode-actions))
    (context-list-replace-widgets! 'mozc mozc-widgets)))

(define mozc-context-rec-spec
  (append
   context-rec-spec
   ;; renamed from 'id' to avoid conflict with context-id
   (list
     (list 'mc-id             #f)
     (list 'on                #f)
     (list 'commit-raw        #t))))
(define-record 'mozc-context mozc-context-rec-spec)
(define mozc-context-new-internal mozc-context-new)

(define mozc-context-new
  (lambda (id im name)
    (let* ((mc (mozc-context-new-internal id im))
	   (mc-id (mozc-lib-alloc-context mc)))
      (mozc-context-set-widgets! mc mozc-widgets)
      (mozc-context-set-mc-id! mc mc-id)
      mc)))

(define mozc-proc-direct-state
  (lambda (mc key key-state)
   (if (mozc-on-key? key key-state)
     (begin
       (mozc-lib-set-on (mozc-context-mc-id mc))
       (mozc-context-set-on! mc #t))
       (mozc-commit-raw mc))))

(define mozc-commit-raw
  (lambda (mc)
    (im-commit-raw mc)
    (mozc-context-set-commit-raw! mc #t)))

(define mozc-init-handler
  (lambda (id im arg)
    (mozc-context-new id im arg)))

(define mozc-release-handler
  (lambda (mc)
    (let ((mc-id (mozc-context-mc-id mc)))
      (if mc-id
        (mozc-lib-free-context mc-id)
        #f)
    #f)))

(define mozc-proc-input-state
  (lambda (mc key key-state)
    (let* ((mid (mozc-context-mc-id mc)))
          (if (mozc-off-key? key key-state)
	      (mozc-lib-set-input-mode mc mid mozc-type-direct)
	      (if (mozc-lib-press-key mc mid (if (symbol? key)
                                            (keysym-to-int key)
                                            key) key-state)
                  #f  ; Key event is consumed
		(mozc-commit-raw mc)
                )))))


(define mozc-press-key-handler
  (lambda (mc key key-state)
    (if (mozc-context-on mc)
      (mozc-proc-input-state mc key key-state)
      (mozc-proc-direct-state mc key key-state)
      )))

(define mozc-release-key-handler
  (lambda (mc key key-state)
    #f))

(define mozc-reset-handler
  (lambda (mc)
    (let ((mid (mozc-context-mc-id mc)))
      (mozc-lib-reset mid))))

(define mozc-focus-in-handler
  (lambda (mc)
    (let ((mid (mozc-context-mc-id mc)))
      ;(mozc-lib-focus-in mid)
      )))

(define mozc-focus-out-handler
  (lambda (mc)
    (let ((mid (mozc-context-mc-id mc)))
      ;(mozc-lib-focus-out mid)
      )))

(define mozc-get-candidate-handler
  (lambda (mc idx accel-enum-hint)
    (let* ((mid (mozc-context-mc-id mc))
	   (cand
             (mozc-lib-get-nth-candidate mid idx)))
      (list cand (digit->string (+ (remainder idx 9) 1)) ""))))

(define mozc-set-candidate-index-handler
  (lambda (mc idx)
    #f))

(mozc-configure-widgets)

(register-im
  'mozc
  "ja"
  "UTF-8"
  mozc-im-name-label
  mozc-im-short-desc
  #f
  mozc-init-handler
  mozc-release-handler
  context-mode-handler
  mozc-press-key-handler
  mozc-release-key-handler
  mozc-reset-handler
  mozc-get-candidate-handler
  mozc-set-candidate-index-handler
  context-prop-activate-handler
  #f
  mozc-focus-in-handler
  mozc-focus-out-handler
  #f
  #f
)