;;; This file is part of LISA, the Lisp-based Intelligent Software
;;; Agents platform.

;;; Copyright (C) 2000 David E. Young (de.young@computer.org)

;;; This library is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU Lesser General Public License
;;; as published by the Free Software Foundation; either version 2.1
;;; of the License, or (at your option) any later version.

;;; This library is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU Lesser General Public License for more details.

;;; You should have received a copy of the GNU Lesser General Public License
;;; along with this library; if not, write to the Free Software
;;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

;;; File: retrieve.lisp
;;; Description: Macros and functions implementing LISA's early attempt at a
;;; query language.

;;; $Id: retrieve.lisp,v 1.6 2002/01/10 16:52:15 youngde Exp $

(in-package "LISA")

(defvar *query-result* nil)

;;; NB: This is an experimental implementation of Queries for LISA. As such,
;;; it cheats in various ways to limit the impact on other parts of the
;;; system. For example, this code creates a temporary inference engine each
;;; time a query is issued, borrowing the FACT table from CURRENT-ENGINE in
;;; the process. This is not a permanent solution, but it will remain in place
;;; while I gather feedback on the overall query mechanism.

(defun define-and-run-query (name body)
  (let ((*query-result* '())
        (query-engine (make-inference-engine)))
    (setf (get-facts query-engine) (get-facts (current-engine)))
    (with-inference-engine (query-engine)
      (add-rule query-engine (define-rule name body))
      (run)
      (values *query-result*))))

(defmacro defquery (name &body body)
  (let ((rule-name (gensym)))
    `(let ((,rule-name
            (if (consp ',name) ,name ',name)))
       (define-and-run-query ,rule-name ',body))))

(defmacro retrieve ((&rest varlist) &body body)
  (flet ((make-query-binding (var)
           `(cons ',var (instance-of-shadow-fact ,var))))
    `(defquery (gensym)
       ,@body
       =>
       (push (list ,@(mapcar #'make-query-binding varlist)) *query-result*))))
