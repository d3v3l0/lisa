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

;;; File: terminal-node.lisp
;;; Description:

;;; $Id: terminal-node.lisp,v 1.5 2002/09/24 15:26:42 youngde Exp $

(in-package "LISA")

(defclass terminal-node ()
  ((rule :initarg :rule
         :initform nil
         :reader terminal-node-rule)
   (rule-activations :initform (make-hash-table)
                     :accessor terminal-node-rule-activations)))

(defmethod accept-token ((self terminal-node) (tokens add-token))
  (let* ((rule (terminal-node-rule self))
         (activation (make-activation rule tokens)))
    (format t "addition activation for ~S~%" tokens)
    (add-activation (rule-engine rule) activation)
    (setf (gethash (hash-code tokens) (terminal-node-rule-activations self))
      activation)
    t))

(defmethod accept-token ((self terminal-node) (tokens remove-token))
  (with-accessors ((activations terminal-node-rule-activations)) self
    (let ((activation (gethash (hash-code tokens) activations)))
      (unless (null activation)
        (disable-activation (rule-engine (terminal-node-rule self)) activation)
        (remhash (hash-code tokens) activations)))
    t))

(defmethod accept-token ((self terminal-node) (token reset-token))
  (clrhash (terminal-node-rule-activations self))
  t)

(defun make-terminal-node (rule)
  (make-instance 'terminal-node :rule rule))
