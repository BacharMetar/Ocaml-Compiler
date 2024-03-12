;;; prologue-1.asm
;;; The first part of the standard prologue for compiled programs
;;;
;;; Programmer: Mayer Goldberg, 2023

%define T_void 				0
%define T_nil 				1
%define T_char 				2
%define T_string 			3
%define T_closure 			4
%define T_undefined			5
%define T_boolean 			8
%define T_boolean_false 		(T_boolean | 1)
%define T_boolean_true 			(T_boolean | 2)
%define T_number 			16
%define T_integer			(T_number | 1)
%define T_fraction 			(T_number | 2)
%define T_real 				(T_number | 3)
%define T_collection 			32
%define T_pair 				(T_collection | 1)
%define T_vector 			(T_collection | 2)
%define T_symbol 			64
%define T_interned_symbol		(T_symbol | 1)
%define T_uninterned_symbol		(T_symbol | 2)

%define SOB_CHAR_VALUE(reg) 		byte [reg + 1]
%define SOB_PAIR_CAR(reg)		qword [reg + 1]
%define SOB_PAIR_CDR(reg)		qword [reg + 1 + 8]
%define SOB_STRING_LENGTH(reg)		qword [reg + 1]
%define SOB_VECTOR_LENGTH(reg)		qword [reg + 1]
%define SOB_CLOSURE_ENV(reg)		qword [reg + 1]
%define SOB_CLOSURE_CODE(reg)		qword [reg + 1 + 8]

%define OLD_RDP 			qword [rbp]
%define RET_ADDR 			qword [rbp + 8 * 1]
%define ENV 				qword [rbp + 8 * 2]
%define COUNT 				qword [rbp + 8 * 3]
%define PARAM(n) 			qword [rbp + 8 * (4 + n)]
%define AND_KILL_FRAME(n)		(8 * (2 + n))

%define MAGIC				496351

%macro ENTER 0
	enter 0, 0
	and rsp, ~15
%endmacro

%macro LEAVE 0
	leave
%endmacro

%macro assert_type 2
        cmp byte [%1], %2
        jne L_error_incorrect_type
%endmacro

%define assert_void(reg)		assert_type reg, T_void
%define assert_nil(reg)			assert_type reg, T_nil
%define assert_char(reg)		assert_type reg, T_char
%define assert_string(reg)		assert_type reg, T_string
%define assert_symbol(reg)		assert_type reg, T_symbol
%define assert_interned_symbol(reg)	assert_type reg, T_interned_symbol
%define assert_uninterned_symbol(reg)	assert_type reg, T_uninterned_symbol
%define assert_closure(reg)		assert_type reg, T_closure
%define assert_boolean(reg)		assert_type reg, T_boolean
%define assert_integer(reg)		assert_type reg, T_integer
%define assert_fraction(reg)		assert_type reg, T_fraction
%define assert_real(reg)		assert_type reg, T_real
%define assert_pair(reg)		assert_type reg, T_pair
%define assert_vector(reg)		assert_type reg, T_vector

%define sob_void			(L_constants + 0)
%define sob_nil				(L_constants + 1)
%define sob_boolean_false		(L_constants + 2)
%define sob_boolean_true		(L_constants + 3)
%define sob_char_nul			(L_constants + 4)

%define bytes(n)			(n)
%define kbytes(n) 			(bytes(n) << 10)
%define mbytes(n) 			(kbytes(n) << 10)
%define gbytes(n) 			(mbytes(n) << 10)

section .data
L_constants:
	; L_constants + 0:
	db T_void
	; L_constants + 1:
	db T_nil
	; L_constants + 2:
	db T_boolean_false
	; L_constants + 3:
	db T_boolean_true
	; L_constants + 4:
	db T_char, 0x00	; #\nul
	; L_constants + 6:
	db T_string	; "null?"
	dq 5
	db 0x6E, 0x75, 0x6C, 0x6C, 0x3F
	; L_constants + 20:
	db T_string	; "pair?"
	dq 5
	db 0x70, 0x61, 0x69, 0x72, 0x3F
	; L_constants + 34:
	db T_string	; "void?"
	dq 5
	db 0x76, 0x6F, 0x69, 0x64, 0x3F
	; L_constants + 48:
	db T_string	; "char?"
	dq 5
	db 0x63, 0x68, 0x61, 0x72, 0x3F
	; L_constants + 62:
	db T_string	; "string?"
	dq 7
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3F
	; L_constants + 78:
	db T_string	; "interned-symbol?"
	dq 16
	db 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E, 0x65, 0x64
	db 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 103:
	db T_string	; "vector?"
	dq 7
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x3F
	; L_constants + 119:
	db T_string	; "procedure?"
	dq 10
	db 0x70, 0x72, 0x6F, 0x63, 0x65, 0x64, 0x75, 0x72
	db 0x65, 0x3F
	; L_constants + 138:
	db T_string	; "real?"
	dq 5
	db 0x72, 0x65, 0x61, 0x6C, 0x3F
	; L_constants + 152:
	db T_string	; "fraction?"
	dq 9
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x3F
	; L_constants + 170:
	db T_string	; "boolean?"
	dq 8
	db 0x62, 0x6F, 0x6F, 0x6C, 0x65, 0x61, 0x6E, 0x3F
	; L_constants + 187:
	db T_string	; "number?"
	dq 7
	db 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x3F
	; L_constants + 203:
	db T_string	; "collection?"
	dq 11
	db 0x63, 0x6F, 0x6C, 0x6C, 0x65, 0x63, 0x74, 0x69
	db 0x6F, 0x6E, 0x3F
	; L_constants + 223:
	db T_string	; "cons"
	dq 4
	db 0x63, 0x6F, 0x6E, 0x73
	; L_constants + 236:
	db T_string	; "display-sexpr"
	dq 13
	db 0x64, 0x69, 0x73, 0x70, 0x6C, 0x61, 0x79, 0x2D
	db 0x73, 0x65, 0x78, 0x70, 0x72
	; L_constants + 258:
	db T_string	; "write-char"
	dq 10
	db 0x77, 0x72, 0x69, 0x74, 0x65, 0x2D, 0x63, 0x68
	db 0x61, 0x72
	; L_constants + 277:
	db T_string	; "car"
	dq 3
	db 0x63, 0x61, 0x72
	; L_constants + 289:
	db T_string	; "cdr"
	dq 3
	db 0x63, 0x64, 0x72
	; L_constants + 301:
	db T_string	; "string-length"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 323:
	db T_string	; "vector-length"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x6C
	db 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 345:
	db T_string	; "real->integer"
	dq 13
	db 0x72, 0x65, 0x61, 0x6C, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 367:
	db T_string	; "exit"
	dq 4
	db 0x65, 0x78, 0x69, 0x74
	; L_constants + 380:
	db T_string	; "integer->real"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 402:
	db T_string	; "fraction->real"
	dq 14
	db 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F, 0x6E
	db 0x2D, 0x3E, 0x72, 0x65, 0x61, 0x6C
	; L_constants + 425:
	db T_string	; "char->integer"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x3E, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72
	; L_constants + 447:
	db T_string	; "integer->char"
	dq 13
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x2D
	db 0x3E, 0x63, 0x68, 0x61, 0x72
	; L_constants + 469:
	db T_string	; "trng"
	dq 4
	db 0x74, 0x72, 0x6E, 0x67
	; L_constants + 482:
	db T_string	; "zero?"
	dq 5
	db 0x7A, 0x65, 0x72, 0x6F, 0x3F
	; L_constants + 496:
	db T_string	; "integer?"
	dq 8
	db 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65, 0x72, 0x3F
	; L_constants + 513:
	db T_string	; "__bin-apply"
	dq 11
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x70
	db 0x70, 0x6C, 0x79
	; L_constants + 533:
	db T_string	; "__bin-add-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x72, 0x72
	; L_constants + 554:
	db T_string	; "__bin-sub-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x72, 0x72
	; L_constants + 575:
	db T_string	; "__bin-mul-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 596:
	db T_string	; "__bin-div-rr"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x72, 0x72
	; L_constants + 617:
	db T_string	; "__bin-add-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x71, 0x71
	; L_constants + 638:
	db T_string	; "__bin-sub-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x71, 0x71
	; L_constants + 659:
	db T_string	; "__bin-mul-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 680:
	db T_string	; "__bin-div-qq"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x71, 0x71
	; L_constants + 701:
	db T_string	; "__bin-add-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x61, 0x64
	db 0x64, 0x2D, 0x7A, 0x7A
	; L_constants + 722:
	db T_string	; "__bin-sub-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x73, 0x75
	db 0x62, 0x2D, 0x7A, 0x7A
	; L_constants + 743:
	db T_string	; "__bin-mul-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6D, 0x75
	db 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 764:
	db T_string	; "__bin-div-zz"
	dq 12
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x64, 0x69
	db 0x76, 0x2D, 0x7A, 0x7A
	; L_constants + 785:
	db T_string	; "error"
	dq 5
	db 0x65, 0x72, 0x72, 0x6F, 0x72
	; L_constants + 799:
	db T_string	; "__bin-less-than-rr"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x72, 0x72
	; L_constants + 826:
	db T_string	; "__bin-less-than-qq"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x71, 0x71
	; L_constants + 853:
	db T_string	; "__bin-less-than-zz"
	dq 18
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x6C, 0x65
	db 0x73, 0x73, 0x2D, 0x74, 0x68, 0x61, 0x6E, 0x2D
	db 0x7A, 0x7A
	; L_constants + 880:
	db T_string	; "__bin-equal-rr"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x72, 0x72
	; L_constants + 903:
	db T_string	; "__bin-equal-qq"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x71, 0x71
	; L_constants + 926:
	db T_string	; "__bin-equal-zz"
	dq 14
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x2D, 0x65, 0x71
	db 0x75, 0x61, 0x6C, 0x2D, 0x7A, 0x7A
	; L_constants + 949:
	db T_string	; "quotient"
	dq 8
	db 0x71, 0x75, 0x6F, 0x74, 0x69, 0x65, 0x6E, 0x74
	; L_constants + 966:
	db T_string	; "remainder"
	dq 9
	db 0x72, 0x65, 0x6D, 0x61, 0x69, 0x6E, 0x64, 0x65
	db 0x72
	; L_constants + 984:
	db T_string	; "set-car!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x61, 0x72, 0x21
	; L_constants + 1001:
	db T_string	; "set-cdr!"
	dq 8
	db 0x73, 0x65, 0x74, 0x2D, 0x63, 0x64, 0x72, 0x21
	; L_constants + 1018:
	db T_string	; "string-ref"
	dq 10
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1037:
	db T_string	; "vector-ref"
	dq 10
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x66
	; L_constants + 1056:
	db T_string	; "vector-set!"
	dq 11
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1076:
	db T_string	; "string-set!"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x73
	db 0x65, 0x74, 0x21
	; L_constants + 1096:
	db T_string	; "make-vector"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72
	; L_constants + 1116:
	db T_string	; "make-string"
	dq 11
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67
	; L_constants + 1136:
	db T_string	; "numerator"
	dq 9
	db 0x6E, 0x75, 0x6D, 0x65, 0x72, 0x61, 0x74, 0x6F
	db 0x72
	; L_constants + 1154:
	db T_string	; "denominator"
	dq 11
	db 0x64, 0x65, 0x6E, 0x6F, 0x6D, 0x69, 0x6E, 0x61
	db 0x74, 0x6F, 0x72
	; L_constants + 1174:
	db T_string	; "eq?"
	dq 3
	db 0x65, 0x71, 0x3F
	; L_constants + 1186:
	db T_string	; "__integer-to-fracti...
	dq 21
	db 0x5F, 0x5F, 0x69, 0x6E, 0x74, 0x65, 0x67, 0x65
	db 0x72, 0x2D, 0x74, 0x6F, 0x2D, 0x66, 0x72, 0x61
	db 0x63, 0x74, 0x69, 0x6F, 0x6E
	; L_constants + 1216:
	db T_string	; "logand"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x61, 0x6E, 0x64
	; L_constants + 1231:
	db T_string	; "logor"
	dq 5
	db 0x6C, 0x6F, 0x67, 0x6F, 0x72
	; L_constants + 1245:
	db T_string	; "logxor"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x78, 0x6F, 0x72
	; L_constants + 1260:
	db T_string	; "lognot"
	dq 6
	db 0x6C, 0x6F, 0x67, 0x6E, 0x6F, 0x74
	; L_constants + 1275:
	db T_string	; "ash"
	dq 3
	db 0x61, 0x73, 0x68
	; L_constants + 1287:
	db T_string	; "symbol?"
	dq 7
	db 0x73, 0x79, 0x6D, 0x62, 0x6F, 0x6C, 0x3F
	; L_constants + 1303:
	db T_string	; "uninterned-symbol?"
	dq 18
	db 0x75, 0x6E, 0x69, 0x6E, 0x74, 0x65, 0x72, 0x6E
	db 0x65, 0x64, 0x2D, 0x73, 0x79, 0x6D, 0x62, 0x6F
	db 0x6C, 0x3F
	; L_constants + 1330:
	db T_string	; "gensym?"
	dq 7
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D, 0x3F
	; L_constants + 1346:
	db T_string	; "gensym"
	dq 6
	db 0x67, 0x65, 0x6E, 0x73, 0x79, 0x6D
	; L_constants + 1361:
	db T_string	; "frame"
	dq 5
	db 0x66, 0x72, 0x61, 0x6D, 0x65
	; L_constants + 1375:
	db T_string	; "break"
	dq 5
	db 0x62, 0x72, 0x65, 0x61, 0x6B
	; L_constants + 1389:
	db T_string	; "caar"
	dq 4
	db 0x63, 0x61, 0x61, 0x72
	; L_constants + 1402:
	db T_string	; "cadr"
	dq 4
	db 0x63, 0x61, 0x64, 0x72
	; L_constants + 1415:
	db T_string	; "cdar"
	dq 4
	db 0x63, 0x64, 0x61, 0x72
	; L_constants + 1428:
	db T_string	; "cddr"
	dq 4
	db 0x63, 0x64, 0x64, 0x72
	; L_constants + 1441:
	db T_string	; "caaar"
	dq 5
	db 0x63, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1455:
	db T_string	; "caadr"
	dq 5
	db 0x63, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1469:
	db T_string	; "cadar"
	dq 5
	db 0x63, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1483:
	db T_string	; "caddr"
	dq 5
	db 0x63, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1497:
	db T_string	; "cdaar"
	dq 5
	db 0x63, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1511:
	db T_string	; "cdadr"
	dq 5
	db 0x63, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1525:
	db T_string	; "cddar"
	dq 5
	db 0x63, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1539:
	db T_string	; "cdddr"
	dq 5
	db 0x63, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1553:
	db T_string	; "caaaar"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1568:
	db T_string	; "caaadr"
	dq 6
	db 0x63, 0x61, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1583:
	db T_string	; "caadar"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1598:
	db T_string	; "caaddr"
	dq 6
	db 0x63, 0x61, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1613:
	db T_string	; "cadaar"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1628:
	db T_string	; "cadadr"
	dq 6
	db 0x63, 0x61, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1643:
	db T_string	; "caddar"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1658:
	db T_string	; "cadddr"
	dq 6
	db 0x63, 0x61, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1673:
	db T_string	; "cdaaar"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x61, 0x72
	; L_constants + 1688:
	db T_string	; "cdaadr"
	dq 6
	db 0x63, 0x64, 0x61, 0x61, 0x64, 0x72
	; L_constants + 1703:
	db T_string	; "cdadar"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x61, 0x72
	; L_constants + 1718:
	db T_string	; "cdaddr"
	dq 6
	db 0x63, 0x64, 0x61, 0x64, 0x64, 0x72
	; L_constants + 1733:
	db T_string	; "cddaar"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x61, 0x72
	; L_constants + 1748:
	db T_string	; "cddadr"
	dq 6
	db 0x63, 0x64, 0x64, 0x61, 0x64, 0x72
	; L_constants + 1763:
	db T_string	; "cdddar"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x61, 0x72
	; L_constants + 1778:
	db T_string	; "cddddr"
	dq 6
	db 0x63, 0x64, 0x64, 0x64, 0x64, 0x72
	; L_constants + 1793:
	db T_string	; "list?"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x3F
	; L_constants + 1807:
	db T_string	; "list"
	dq 4
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 1820:
	db T_string	; "not"
	dq 3
	db 0x6E, 0x6F, 0x74
	; L_constants + 1832:
	db T_string	; "rational?"
	dq 9
	db 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x61, 0x6C
	db 0x3F
	; L_constants + 1850:
	db T_string	; "list*"
	dq 5
	db 0x6C, 0x69, 0x73, 0x74, 0x2A
	; L_constants + 1864:
	db T_string	; "whatever"
	dq 8
	db 0x77, 0x68, 0x61, 0x74, 0x65, 0x76, 0x65, 0x72
	; L_constants + 1881:
	db T_interned_symbol	; whatever
	dq L_constants + 1864
	; L_constants + 1890:
	db T_string	; "apply"
	dq 5
	db 0x61, 0x70, 0x70, 0x6C, 0x79
	; L_constants + 1904:
	db T_string	; "ormap"
	dq 5
	db 0x6F, 0x72, 0x6D, 0x61, 0x70
	; L_constants + 1918:
	db T_string	; "map"
	dq 3
	db 0x6D, 0x61, 0x70
	; L_constants + 1930:
	db T_string	; "andmap"
	dq 6
	db 0x61, 0x6E, 0x64, 0x6D, 0x61, 0x70
	; L_constants + 1945:
	db T_string	; "reverse"
	dq 7
	db 0x72, 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 1961:
	db T_string	; "fold-left"
	dq 9
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x6C, 0x65, 0x66
	db 0x74
	; L_constants + 1979:
	db T_string	; "append"
	dq 6
	db 0x61, 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 1994:
	db T_string	; "fold-right"
	dq 10
	db 0x66, 0x6F, 0x6C, 0x64, 0x2D, 0x72, 0x69, 0x67
	db 0x68, 0x74
	; L_constants + 2013:
	db T_string	; "+"
	dq 1
	db 0x2B
	; L_constants + 2023:
	db T_integer	; 0
	dq 0
	; L_constants + 2032:
	db T_string	; "__bin_integer_to_fr...
	dq 25
	db 0x5F, 0x5F, 0x62, 0x69, 0x6E, 0x5F, 0x69, 0x6E
	db 0x74, 0x65, 0x67, 0x65, 0x72, 0x5F, 0x74, 0x6F
	db 0x5F, 0x66, 0x72, 0x61, 0x63, 0x74, 0x69, 0x6F
	db 0x6E
	; L_constants + 2066:
	db T_interned_symbol	; +
	dq L_constants + 2013
	; L_constants + 2075:
	db T_string	; "all arguments need ...
	dq 32
	db 0x61, 0x6C, 0x6C, 0x20, 0x61, 0x72, 0x67, 0x75
	db 0x6D, 0x65, 0x6E, 0x74, 0x73, 0x20, 0x6E, 0x65
	db 0x65, 0x64, 0x20, 0x74, 0x6F, 0x20, 0x62, 0x65
	db 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72, 0x73
	; L_constants + 2116:
	db T_string	; "-"
	dq 1
	db 0x2D
	; L_constants + 2126:
	db T_string	; "real"
	dq 4
	db 0x72, 0x65, 0x61, 0x6C
	; L_constants + 2139:
	db T_interned_symbol	; -
	dq L_constants + 2116
	; L_constants + 2148:
	db T_string	; "*"
	dq 1
	db 0x2A
	; L_constants + 2158:
	db T_integer	; 1
	dq 1
	; L_constants + 2167:
	db T_interned_symbol	; *
	dq L_constants + 2148
	; L_constants + 2176:
	db T_string	; "/"
	dq 1
	db 0x2F
	; L_constants + 2186:
	db T_interned_symbol	; /
	dq L_constants + 2176
	; L_constants + 2195:
	db T_string	; "fact"
	dq 4
	db 0x66, 0x61, 0x63, 0x74
	; L_constants + 2208:
	db T_string	; "<"
	dq 1
	db 0x3C
	; L_constants + 2218:
	db T_string	; "<="
	dq 2
	db 0x3C, 0x3D
	; L_constants + 2229:
	db T_string	; ">"
	dq 1
	db 0x3E
	; L_constants + 2239:
	db T_string	; ">="
	dq 2
	db 0x3E, 0x3D
	; L_constants + 2250:
	db T_string	; "="
	dq 1
	db 0x3D
	; L_constants + 2260:
	db T_string	; "generic-comparator"
	dq 18
	db 0x67, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x2D
	db 0x63, 0x6F, 0x6D, 0x70, 0x61, 0x72, 0x61, 0x74
	db 0x6F, 0x72
	; L_constants + 2287:
	db T_interned_symbol	; generic-comparator
	dq L_constants + 2260
	; L_constants + 2296:
	db T_string	; "all the arguments m...
	dq 33
	db 0x61, 0x6C, 0x6C, 0x20, 0x74, 0x68, 0x65, 0x20
	db 0x61, 0x72, 0x67, 0x75, 0x6D, 0x65, 0x6E, 0x74
	db 0x73, 0x20, 0x6D, 0x75, 0x73, 0x74, 0x20, 0x62
	db 0x65, 0x20, 0x6E, 0x75, 0x6D, 0x62, 0x65, 0x72
	db 0x73
	; L_constants + 2338:
	db T_string	; "make-list"
	dq 9
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74
	; L_constants + 2356:
	db T_interned_symbol	; make-list
	dq L_constants + 2338
	; L_constants + 2365:
	db T_string	; "Usage: (make-list l...
	dq 45
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x20, 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x69, 0x6E, 0x69, 0x74, 0x2D
	db 0x63, 0x68, 0x61, 0x72, 0x29
	; L_constants + 2419:
	db T_string	; "char<?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3F
	; L_constants + 2434:
	db T_string	; "char<=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3C, 0x3D, 0x3F
	; L_constants + 2450:
	db T_string	; "char=?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3D, 0x3F
	; L_constants + 2465:
	db T_string	; "char>?"
	dq 6
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3F
	; L_constants + 2480:
	db T_string	; "char>=?"
	dq 7
	db 0x63, 0x68, 0x61, 0x72, 0x3E, 0x3D, 0x3F
	; L_constants + 2496:
	db T_string	; "char-downcase"
	dq 13
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x64, 0x6F, 0x77
	db 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2518:
	db T_string	; "char-upcase"
	dq 11
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x75, 0x70, 0x63
	db 0x61, 0x73, 0x65
	; L_constants + 2538:
	db T_char, 0x41	; #\A
	; L_constants + 2540:
	db T_char, 0x5A	; #\Z
	; L_constants + 2542:
	db T_char, 0x61	; #\a
	; L_constants + 2544:
	db T_char, 0x7A	; #\z
	; L_constants + 2546:
	db T_string	; "char-ci<?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3F
	; L_constants + 2564:
	db T_string	; "char-ci<=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3C
	db 0x3D, 0x3F
	; L_constants + 2583:
	db T_string	; "char-ci=?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3D
	db 0x3F
	; L_constants + 2601:
	db T_string	; "char-ci>?"
	dq 9
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3F
	; L_constants + 2619:
	db T_string	; "char-ci>=?"
	dq 10
	db 0x63, 0x68, 0x61, 0x72, 0x2D, 0x63, 0x69, 0x3E
	db 0x3D, 0x3F
	; L_constants + 2638:
	db T_string	; "string-downcase"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x64
	db 0x6F, 0x77, 0x6E, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2662:
	db T_string	; "string-upcase"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x75
	db 0x70, 0x63, 0x61, 0x73, 0x65
	; L_constants + 2684:
	db T_string	; "list->string"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x73, 0x74
	db 0x72, 0x69, 0x6E, 0x67
	; L_constants + 2705:
	db T_string	; "string->list"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 2726:
	db T_string	; "string<?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3F
	; L_constants + 2743:
	db T_string	; "string<=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3C, 0x3D
	db 0x3F
	; L_constants + 2761:
	db T_string	; "string=?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3D, 0x3F
	; L_constants + 2778:
	db T_string	; "string>=?"
	dq 9
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3D
	db 0x3F
	; L_constants + 2796:
	db T_string	; "string>?"
	dq 8
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x3E, 0x3F
	; L_constants + 2813:
	db T_string	; "string-ci<?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3F
	; L_constants + 2833:
	db T_string	; "string-ci<=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3C, 0x3D, 0x3F
	; L_constants + 2854:
	db T_string	; "string-ci=?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3D, 0x3F
	; L_constants + 2874:
	db T_string	; "string-ci>=?"
	dq 12
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3D, 0x3F
	; L_constants + 2895:
	db T_string	; "string-ci>?"
	dq 11
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x63
	db 0x69, 0x3E, 0x3F
	; L_constants + 2915:
	db T_string	; "length"
	dq 6
	db 0x6C, 0x65, 0x6E, 0x67, 0x74, 0x68
	; L_constants + 2930:
	db T_interned_symbol	; make-vector
	dq L_constants + 1096
	; L_constants + 2939:
	db T_string	; "Usage: (make-vector...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 2991:
	db T_interned_symbol	; make-string
	dq L_constants + 1116
	; L_constants + 3000:
	db T_string	; "Usage: (make-string...
	dq 43
	db 0x55, 0x73, 0x61, 0x67, 0x65, 0x3A, 0x20, 0x28
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x20, 0x73, 0x69, 0x7A, 0x65
	db 0x20, 0x3F, 0x6F, 0x70, 0x74, 0x69, 0x6F, 0x6E
	db 0x61, 0x6C, 0x2D, 0x64, 0x65, 0x66, 0x61, 0x75
	db 0x6C, 0x74, 0x29
	; L_constants + 3052:
	db T_string	; "list->vector"
	dq 12
	db 0x6C, 0x69, 0x73, 0x74, 0x2D, 0x3E, 0x76, 0x65
	db 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3073:
	db T_string	; "vector"
	dq 6
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72
	; L_constants + 3088:
	db T_string	; "vector->list"
	dq 12
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x3E
	db 0x6C, 0x69, 0x73, 0x74
	; L_constants + 3109:
	db T_string	; "random"
	dq 6
	db 0x72, 0x61, 0x6E, 0x64, 0x6F, 0x6D
	; L_constants + 3124:
	db T_string	; "positive?"
	dq 9
	db 0x70, 0x6F, 0x73, 0x69, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3142:
	db T_string	; "negative?"
	dq 9
	db 0x6E, 0x65, 0x67, 0x61, 0x74, 0x69, 0x76, 0x65
	db 0x3F
	; L_constants + 3160:
	db T_string	; "even?"
	dq 5
	db 0x65, 0x76, 0x65, 0x6E, 0x3F
	; L_constants + 3174:
	db T_integer	; 2
	dq 2
	; L_constants + 3183:
	db T_string	; "odd?"
	dq 4
	db 0x6F, 0x64, 0x64, 0x3F
	; L_constants + 3196:
	db T_string	; "abs"
	dq 3
	db 0x61, 0x62, 0x73
	; L_constants + 3208:
	db T_string	; "equal?"
	dq 6
	db 0x65, 0x71, 0x75, 0x61, 0x6C, 0x3F
	; L_constants + 3223:
	db T_string	; "assoc"
	dq 5
	db 0x61, 0x73, 0x73, 0x6F, 0x63
	; L_constants + 3237:
	db T_string	; "string-append"
	dq 13
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3259:
	db T_string	; "vector-append"
	dq 13
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x61
	db 0x70, 0x70, 0x65, 0x6E, 0x64
	; L_constants + 3281:
	db T_string	; "string-reverse"
	dq 14
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3304:
	db T_string	; "vector-reverse"
	dq 14
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65
	; L_constants + 3327:
	db T_string	; "string-reverse!"
	dq 15
	db 0x73, 0x74, 0x72, 0x69, 0x6E, 0x67, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3351:
	db T_string	; "vector-reverse!"
	dq 15
	db 0x76, 0x65, 0x63, 0x74, 0x6F, 0x72, 0x2D, 0x72
	db 0x65, 0x76, 0x65, 0x72, 0x73, 0x65, 0x21
	; L_constants + 3375:
	db T_string	; "make-list-thunk"
	dq 15
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x6C, 0x69, 0x73
	db 0x74, 0x2D, 0x74, 0x68, 0x75, 0x6E, 0x6B
	; L_constants + 3399:
	db T_string	; "make-string-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x73, 0x74, 0x72
	db 0x69, 0x6E, 0x67, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3425:
	db T_string	; "make-vector-thunk"
	dq 17
	db 0x6D, 0x61, 0x6B, 0x65, 0x2D, 0x76, 0x65, 0x63
	db 0x74, 0x6F, 0x72, 0x2D, 0x74, 0x68, 0x75, 0x6E
	db 0x6B
	; L_constants + 3451:
	db T_string	; "logarithm"
	dq 9
	db 0x6C, 0x6F, 0x67, 0x61, 0x72, 0x69, 0x74, 0x68
	db 0x6D
	; L_constants + 3469:
	db T_real	; 1.000000
	dq 1.000000
	; L_constants + 3478:
	db T_string	; "newline"
	dq 7
	db 0x6E, 0x65, 0x77, 0x6C, 0x69, 0x6E, 0x65
	; L_constants + 3494:
	db T_char, 0x0A	; #\newline
free_var_0:	; location of null?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 6

free_var_1:	; location of pair?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 20

free_var_2:	; location of void?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 34

free_var_3:	; location of char?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 48

free_var_4:	; location of string?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 62

free_var_5:	; location of interned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 78

free_var_6:	; location of vector?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 103

free_var_7:	; location of procedure?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 119

free_var_8:	; location of real?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 138

free_var_9:	; location of fraction?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 152

free_var_10:	; location of boolean?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 170

free_var_11:	; location of number?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 187

free_var_12:	; location of collection?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 203

free_var_13:	; location of cons
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 223

free_var_14:	; location of display-sexpr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 236

free_var_15:	; location of write-char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 258

free_var_16:	; location of car
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 277

free_var_17:	; location of cdr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 289

free_var_18:	; location of string-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 301

free_var_19:	; location of vector-length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 323

free_var_20:	; location of real->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 345

free_var_21:	; location of exit
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 367

free_var_22:	; location of integer->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 380

free_var_23:	; location of fraction->real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 402

free_var_24:	; location of char->integer
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 425

free_var_25:	; location of integer->char
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 447

free_var_26:	; location of trng
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 469

free_var_27:	; location of zero?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 482

free_var_28:	; location of integer?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 496

free_var_29:	; location of __bin-apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 513

free_var_30:	; location of __bin-add-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 533

free_var_31:	; location of __bin-sub-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 554

free_var_32:	; location of __bin-mul-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 575

free_var_33:	; location of __bin-div-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 596

free_var_34:	; location of __bin-add-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 617

free_var_35:	; location of __bin-sub-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 638

free_var_36:	; location of __bin-mul-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 659

free_var_37:	; location of __bin-div-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 680

free_var_38:	; location of __bin-add-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 701

free_var_39:	; location of __bin-sub-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 722

free_var_40:	; location of __bin-mul-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 743

free_var_41:	; location of __bin-div-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 764

free_var_42:	; location of error
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 785

free_var_43:	; location of __bin-less-than-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 799

free_var_44:	; location of __bin-less-than-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 826

free_var_45:	; location of __bin-less-than-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 853

free_var_46:	; location of __bin-equal-rr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 880

free_var_47:	; location of __bin-equal-qq
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 903

free_var_48:	; location of __bin-equal-zz
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 926

free_var_49:	; location of quotient
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 949

free_var_50:	; location of remainder
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 966

free_var_51:	; location of set-car!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 984

free_var_52:	; location of set-cdr!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1001

free_var_53:	; location of string-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1018

free_var_54:	; location of vector-ref
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1037

free_var_55:	; location of vector-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1056

free_var_56:	; location of string-set!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1076

free_var_57:	; location of make-vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1096

free_var_58:	; location of make-string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1116

free_var_59:	; location of numerator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1136

free_var_60:	; location of denominator
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1154

free_var_61:	; location of eq?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1174

free_var_62:	; location of __integer-to-fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1186

free_var_63:	; location of logand
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1216

free_var_64:	; location of logor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1231

free_var_65:	; location of logxor
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1245

free_var_66:	; location of lognot
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1260

free_var_67:	; location of ash
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1275

free_var_68:	; location of symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1287

free_var_69:	; location of uninterned-symbol?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1303

free_var_70:	; location of gensym?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1330

free_var_71:	; location of gensym
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1346

free_var_72:	; location of frame
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1361

free_var_73:	; location of break
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1375

free_var_74:	; location of caar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1389

free_var_75:	; location of cadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1402

free_var_76:	; location of cdar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1415

free_var_77:	; location of cddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1428

free_var_78:	; location of caaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1441

free_var_79:	; location of caadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1455

free_var_80:	; location of cadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1469

free_var_81:	; location of caddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1483

free_var_82:	; location of cdaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1497

free_var_83:	; location of cdadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1511

free_var_84:	; location of cddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1525

free_var_85:	; location of cdddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1539

free_var_86:	; location of caaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1553

free_var_87:	; location of caaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1568

free_var_88:	; location of caadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1583

free_var_89:	; location of caaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1598

free_var_90:	; location of cadaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1613

free_var_91:	; location of cadadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1628

free_var_92:	; location of caddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1643

free_var_93:	; location of cadddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1658

free_var_94:	; location of cdaaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1673

free_var_95:	; location of cdaadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1688

free_var_96:	; location of cdadar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1703

free_var_97:	; location of cdaddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1718

free_var_98:	; location of cddaar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1733

free_var_99:	; location of cddadr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1748

free_var_100:	; location of cdddar
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1763

free_var_101:	; location of cddddr
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1778

free_var_102:	; location of list?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1793

free_var_103:	; location of list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1807

free_var_104:	; location of not
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1820

free_var_105:	; location of rational?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1832

free_var_106:	; location of list*
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1850

free_var_107:	; location of apply
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1890

free_var_108:	; location of ormap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1904

free_var_109:	; location of map
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1918

free_var_110:	; location of andmap
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1930

free_var_111:	; location of reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1945

free_var_112:	; location of fold-left
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1961

free_var_113:	; location of append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1979

free_var_114:	; location of fold-right
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 1994

free_var_115:	; location of +
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2013

free_var_116:	; location of __bin_integer_to_fraction
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2032

free_var_117:	; location of -
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2116

free_var_118:	; location of real
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2126

free_var_119:	; location of *
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2148

free_var_120:	; location of /
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2176

free_var_121:	; location of fact
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2195

free_var_122:	; location of <
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2208

free_var_123:	; location of <=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2218

free_var_124:	; location of >
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2229

free_var_125:	; location of >=
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2239

free_var_126:	; location of =
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2250

free_var_127:	; location of make-list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2338

free_var_128:	; location of char<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2419

free_var_129:	; location of char<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2434

free_var_130:	; location of char=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2450

free_var_131:	; location of char>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2465

free_var_132:	; location of char>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2480

free_var_133:	; location of char-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2496

free_var_134:	; location of char-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2518

free_var_135:	; location of char-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2546

free_var_136:	; location of char-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2564

free_var_137:	; location of char-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2583

free_var_138:	; location of char-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2601

free_var_139:	; location of char-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2619

free_var_140:	; location of string-downcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2638

free_var_141:	; location of string-upcase
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2662

free_var_142:	; location of list->string
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2684

free_var_143:	; location of string->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2705

free_var_144:	; location of string<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2726

free_var_145:	; location of string<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2743

free_var_146:	; location of string=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2761

free_var_147:	; location of string>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2778

free_var_148:	; location of string>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2796

free_var_149:	; location of string-ci<?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2813

free_var_150:	; location of string-ci<=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2833

free_var_151:	; location of string-ci=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2854

free_var_152:	; location of string-ci>=?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2874

free_var_153:	; location of string-ci>?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2895

free_var_154:	; location of length
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 2915

free_var_155:	; location of list->vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3052

free_var_156:	; location of vector
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3073

free_var_157:	; location of vector->list
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3088

free_var_158:	; location of random
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3109

free_var_159:	; location of positive?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3124

free_var_160:	; location of negative?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3142

free_var_161:	; location of even?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3160

free_var_162:	; location of odd?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3183

free_var_163:	; location of abs
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3196

free_var_164:	; location of equal?
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3208

free_var_165:	; location of assoc
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3223

free_var_166:	; location of string-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3237

free_var_167:	; location of vector-append
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3259

free_var_168:	; location of string-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3281

free_var_169:	; location of vector-reverse
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3304

free_var_170:	; location of string-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3327

free_var_171:	; location of vector-reverse!
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3351

free_var_172:	; location of make-list-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3375

free_var_173:	; location of make-string-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3399

free_var_174:	; location of make-vector-thunk
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3425

free_var_175:	; location of logarithm
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3451

free_var_176:	; location of newline
	dq .undefined_object
.undefined_object:
	db T_undefined
	dq L_constants + 3478


extern printf, fprintf, stdout, stderr, fwrite, exit, putchar, getchar
global main
section .text
main:
        enter 0, 0
        
	; building closure for null?
	mov rdi, free_var_0
	mov rsi, L_code_ptr_is_null
	call bind_primitive

	; building closure for pair?
	mov rdi, free_var_1
	mov rsi, L_code_ptr_is_pair
	call bind_primitive

	; building closure for void?
	mov rdi, free_var_2
	mov rsi, L_code_ptr_is_void
	call bind_primitive

	; building closure for char?
	mov rdi, free_var_3
	mov rsi, L_code_ptr_is_char
	call bind_primitive

	; building closure for string?
	mov rdi, free_var_4
	mov rsi, L_code_ptr_is_string
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_5
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for vector?
	mov rdi, free_var_6
	mov rsi, L_code_ptr_is_vector
	call bind_primitive

	; building closure for procedure?
	mov rdi, free_var_7
	mov rsi, L_code_ptr_is_closure
	call bind_primitive

	; building closure for real?
	mov rdi, free_var_8
	mov rsi, L_code_ptr_is_real
	call bind_primitive

	; building closure for fraction?
	mov rdi, free_var_9
	mov rsi, L_code_ptr_is_fraction
	call bind_primitive

	; building closure for boolean?
	mov rdi, free_var_10
	mov rsi, L_code_ptr_is_boolean
	call bind_primitive

	; building closure for number?
	mov rdi, free_var_11
	mov rsi, L_code_ptr_is_number
	call bind_primitive

	; building closure for collection?
	mov rdi, free_var_12
	mov rsi, L_code_ptr_is_collection
	call bind_primitive

	; building closure for cons
	mov rdi, free_var_13
	mov rsi, L_code_ptr_cons
	call bind_primitive

	; building closure for display-sexpr
	mov rdi, free_var_14
	mov rsi, L_code_ptr_display_sexpr
	call bind_primitive

	; building closure for write-char
	mov rdi, free_var_15
	mov rsi, L_code_ptr_write_char
	call bind_primitive

	; building closure for car
	mov rdi, free_var_16
	mov rsi, L_code_ptr_car
	call bind_primitive

	; building closure for cdr
	mov rdi, free_var_17
	mov rsi, L_code_ptr_cdr
	call bind_primitive

	; building closure for string-length
	mov rdi, free_var_18
	mov rsi, L_code_ptr_string_length
	call bind_primitive

	; building closure for vector-length
	mov rdi, free_var_19
	mov rsi, L_code_ptr_vector_length
	call bind_primitive

	; building closure for real->integer
	mov rdi, free_var_20
	mov rsi, L_code_ptr_real_to_integer
	call bind_primitive

	; building closure for exit
	mov rdi, free_var_21
	mov rsi, L_code_ptr_exit
	call bind_primitive

	; building closure for integer->real
	mov rdi, free_var_22
	mov rsi, L_code_ptr_integer_to_real
	call bind_primitive

	; building closure for fraction->real
	mov rdi, free_var_23
	mov rsi, L_code_ptr_fraction_to_real
	call bind_primitive

	; building closure for char->integer
	mov rdi, free_var_24
	mov rsi, L_code_ptr_char_to_integer
	call bind_primitive

	; building closure for integer->char
	mov rdi, free_var_25
	mov rsi, L_code_ptr_integer_to_char
	call bind_primitive

	; building closure for trng
	mov rdi, free_var_26
	mov rsi, L_code_ptr_trng
	call bind_primitive

	; building closure for zero?
	mov rdi, free_var_27
	mov rsi, L_code_ptr_is_zero
	call bind_primitive

	; building closure for integer?
	mov rdi, free_var_28
	mov rsi, L_code_ptr_is_integer
	call bind_primitive

	; building closure for __bin-apply
	mov rdi, free_var_29
	mov rsi, L_code_ptr_bin_apply
	call bind_primitive

	; building closure for __bin-add-rr
	mov rdi, free_var_30
	mov rsi, L_code_ptr_raw_bin_add_rr
	call bind_primitive

	; building closure for __bin-sub-rr
	mov rdi, free_var_31
	mov rsi, L_code_ptr_raw_bin_sub_rr
	call bind_primitive

	; building closure for __bin-mul-rr
	mov rdi, free_var_32
	mov rsi, L_code_ptr_raw_bin_mul_rr
	call bind_primitive

	; building closure for __bin-div-rr
	mov rdi, free_var_33
	mov rsi, L_code_ptr_raw_bin_div_rr
	call bind_primitive

	; building closure for __bin-add-qq
	mov rdi, free_var_34
	mov rsi, L_code_ptr_raw_bin_add_qq
	call bind_primitive

	; building closure for __bin-sub-qq
	mov rdi, free_var_35
	mov rsi, L_code_ptr_raw_bin_sub_qq
	call bind_primitive

	; building closure for __bin-mul-qq
	mov rdi, free_var_36
	mov rsi, L_code_ptr_raw_bin_mul_qq
	call bind_primitive

	; building closure for __bin-div-qq
	mov rdi, free_var_37
	mov rsi, L_code_ptr_raw_bin_div_qq
	call bind_primitive

	; building closure for __bin-add-zz
	mov rdi, free_var_38
	mov rsi, L_code_ptr_raw_bin_add_zz
	call bind_primitive

	; building closure for __bin-sub-zz
	mov rdi, free_var_39
	mov rsi, L_code_ptr_raw_bin_sub_zz
	call bind_primitive

	; building closure for __bin-mul-zz
	mov rdi, free_var_40
	mov rsi, L_code_ptr_raw_bin_mul_zz
	call bind_primitive

	; building closure for __bin-div-zz
	mov rdi, free_var_41
	mov rsi, L_code_ptr_raw_bin_div_zz
	call bind_primitive

	; building closure for error
	mov rdi, free_var_42
	mov rsi, L_code_ptr_error
	call bind_primitive

	; building closure for __bin-less-than-rr
	mov rdi, free_var_43
	mov rsi, L_code_ptr_raw_less_than_rr
	call bind_primitive

	; building closure for __bin-less-than-qq
	mov rdi, free_var_44
	mov rsi, L_code_ptr_raw_less_than_qq
	call bind_primitive

	; building closure for __bin-less-than-zz
	mov rdi, free_var_45
	mov rsi, L_code_ptr_raw_less_than_zz
	call bind_primitive

	; building closure for __bin-equal-rr
	mov rdi, free_var_46
	mov rsi, L_code_ptr_raw_equal_rr
	call bind_primitive

	; building closure for __bin-equal-qq
	mov rdi, free_var_47
	mov rsi, L_code_ptr_raw_equal_qq
	call bind_primitive

	; building closure for __bin-equal-zz
	mov rdi, free_var_48
	mov rsi, L_code_ptr_raw_equal_zz
	call bind_primitive

	; building closure for quotient
	mov rdi, free_var_49
	mov rsi, L_code_ptr_quotient
	call bind_primitive

	; building closure for remainder
	mov rdi, free_var_50
	mov rsi, L_code_ptr_remainder
	call bind_primitive

	; building closure for set-car!
	mov rdi, free_var_51
	mov rsi, L_code_ptr_set_car
	call bind_primitive

	; building closure for set-cdr!
	mov rdi, free_var_52
	mov rsi, L_code_ptr_set_cdr
	call bind_primitive

	; building closure for string-ref
	mov rdi, free_var_53
	mov rsi, L_code_ptr_string_ref
	call bind_primitive

	; building closure for vector-ref
	mov rdi, free_var_54
	mov rsi, L_code_ptr_vector_ref
	call bind_primitive

	; building closure for vector-set!
	mov rdi, free_var_55
	mov rsi, L_code_ptr_vector_set
	call bind_primitive

	; building closure for string-set!
	mov rdi, free_var_56
	mov rsi, L_code_ptr_string_set
	call bind_primitive

	; building closure for make-vector
	mov rdi, free_var_57
	mov rsi, L_code_ptr_make_vector
	call bind_primitive

	; building closure for make-string
	mov rdi, free_var_58
	mov rsi, L_code_ptr_make_string
	call bind_primitive

	; building closure for numerator
	mov rdi, free_var_59
	mov rsi, L_code_ptr_numerator
	call bind_primitive

	; building closure for denominator
	mov rdi, free_var_60
	mov rsi, L_code_ptr_denominator
	call bind_primitive

	; building closure for eq?
	mov rdi, free_var_61
	mov rsi, L_code_ptr_is_eq
	call bind_primitive

	; building closure for __integer-to-fraction
	mov rdi, free_var_62
	mov rsi, L_code_ptr_integer_to_fraction
	call bind_primitive

	; building closure for logand
	mov rdi, free_var_63
	mov rsi, L_code_ptr_logand
	call bind_primitive

	; building closure for logor
	mov rdi, free_var_64
	mov rsi, L_code_ptr_logor
	call bind_primitive

	; building closure for logxor
	mov rdi, free_var_65
	mov rsi, L_code_ptr_logxor
	call bind_primitive

	; building closure for lognot
	mov rdi, free_var_66
	mov rsi, L_code_ptr_lognot
	call bind_primitive

	; building closure for ash
	mov rdi, free_var_67
	mov rsi, L_code_ptr_ash
	call bind_primitive

	; building closure for symbol?
	mov rdi, free_var_68
	mov rsi, L_code_ptr_is_symbol
	call bind_primitive

	; building closure for uninterned-symbol?
	mov rdi, free_var_69
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for gensym?
	mov rdi, free_var_70
	mov rsi, L_code_ptr_is_uninterned_symbol
	call bind_primitive

	; building closure for interned-symbol?
	mov rdi, free_var_5
	mov rsi, L_code_ptr_is_interned_symbol
	call bind_primitive

	; building closure for gensym
	mov rdi, free_var_71
	mov rsi, L_code_ptr_gensym
	call bind_primitive

	; building closure for frame
	mov rdi, free_var_72
	mov rsi, L_code_ptr_frame
	call bind_primitive

	; building closure for break
	mov rdi, free_var_73
	mov rsi, L_code_ptr_break
	call bind_primitive

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3ba9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3ba9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3ba9
.L_lambda_simple_env_end_3ba9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3ba9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3ba9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3ba9
.L_lambda_simple_params_end_3ba9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3ba9
	jmp .L_lambda_simple_end_3ba9
.L_lambda_simple_code_3ba9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3ba9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3ba9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4dfb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4dfb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4dfb
.L_tc_recycle_frame_done_4dfb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3ba9:	; new closure is in rax
	mov qword [free_var_74], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3baa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3baa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3baa
.L_lambda_simple_env_end_3baa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3baa:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3baa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3baa
.L_lambda_simple_params_end_3baa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3baa
	jmp .L_lambda_simple_end_3baa
.L_lambda_simple_code_3baa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3baa
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3baa:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4dfc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4dfc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4dfc
.L_tc_recycle_frame_done_4dfc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3baa:	; new closure is in rax
	mov qword [free_var_75], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bab:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bab
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bab
.L_lambda_simple_env_end_3bab:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bab:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bab
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bab
.L_lambda_simple_params_end_3bab:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bab
	jmp .L_lambda_simple_end_3bab
.L_lambda_simple_code_3bab:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bab
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bab:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4dfd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4dfd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4dfd
.L_tc_recycle_frame_done_4dfd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bab:	; new closure is in rax
	mov qword [free_var_76], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bac:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bac
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bac
.L_lambda_simple_env_end_3bac:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bac:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bac
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bac
.L_lambda_simple_params_end_3bac:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bac
	jmp .L_lambda_simple_end_3bac
.L_lambda_simple_code_3bac:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bac
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bac:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4dfe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4dfe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4dfe
.L_tc_recycle_frame_done_4dfe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bac:	; new closure is in rax
	mov qword [free_var_77], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bad:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bad
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bad
.L_lambda_simple_env_end_3bad:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bad:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bad
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bad
.L_lambda_simple_params_end_3bad:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bad
	jmp .L_lambda_simple_end_3bad
.L_lambda_simple_code_3bad:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bad
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bad:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4dff:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4dff
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4dff
.L_tc_recycle_frame_done_4dff:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bad:	; new closure is in rax
	mov qword [free_var_78], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bae:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bae
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bae
.L_lambda_simple_env_end_3bae:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bae:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bae
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bae
.L_lambda_simple_params_end_3bae:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bae
	jmp .L_lambda_simple_end_3bae
.L_lambda_simple_code_3bae:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bae
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bae:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e00:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e00
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e00
.L_tc_recycle_frame_done_4e00:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bae:	; new closure is in rax
	mov qword [free_var_79], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3baf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3baf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3baf
.L_lambda_simple_env_end_3baf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3baf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3baf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3baf
.L_lambda_simple_params_end_3baf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3baf
	jmp .L_lambda_simple_end_3baf
.L_lambda_simple_code_3baf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3baf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3baf:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e01:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e01
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e01
.L_tc_recycle_frame_done_4e01:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3baf:	; new closure is in rax
	mov qword [free_var_80], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb0
.L_lambda_simple_env_end_3bb0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb0
.L_lambda_simple_params_end_3bb0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb0
	jmp .L_lambda_simple_end_3bb0
.L_lambda_simple_code_3bb0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e02:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e02
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e02
.L_tc_recycle_frame_done_4e02:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb0:	; new closure is in rax
	mov qword [free_var_81], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb1
.L_lambda_simple_env_end_3bb1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb1
.L_lambda_simple_params_end_3bb1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb1
	jmp .L_lambda_simple_end_3bb1
.L_lambda_simple_code_3bb1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e03:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e03
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e03
.L_tc_recycle_frame_done_4e03:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb1:	; new closure is in rax
	mov qword [free_var_82], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb2
.L_lambda_simple_env_end_3bb2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb2
.L_lambda_simple_params_end_3bb2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb2
	jmp .L_lambda_simple_end_3bb2
.L_lambda_simple_code_3bb2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e04:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e04
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e04
.L_tc_recycle_frame_done_4e04:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb2:	; new closure is in rax
	mov qword [free_var_83], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb3
.L_lambda_simple_env_end_3bb3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb3
.L_lambda_simple_params_end_3bb3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb3
	jmp .L_lambda_simple_end_3bb3
.L_lambda_simple_code_3bb3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e05:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e05
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e05
.L_tc_recycle_frame_done_4e05:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb3:	; new closure is in rax
	mov qword [free_var_84], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb4
.L_lambda_simple_env_end_3bb4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb4
.L_lambda_simple_params_end_3bb4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb4
	jmp .L_lambda_simple_end_3bb4
.L_lambda_simple_code_3bb4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e06:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e06
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e06
.L_tc_recycle_frame_done_4e06:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb4:	; new closure is in rax
	mov qword [free_var_85], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb5
.L_lambda_simple_env_end_3bb5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb5
.L_lambda_simple_params_end_3bb5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb5
	jmp .L_lambda_simple_end_3bb5
.L_lambda_simple_code_3bb5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb5:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e07:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e07
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e07
.L_tc_recycle_frame_done_4e07:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb5:	; new closure is in rax
	mov qword [free_var_86], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb6
.L_lambda_simple_env_end_3bb6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb6
.L_lambda_simple_params_end_3bb6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb6
	jmp .L_lambda_simple_end_3bb6
.L_lambda_simple_code_3bb6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e08:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e08
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e08
.L_tc_recycle_frame_done_4e08:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb6:	; new closure is in rax
	mov qword [free_var_87], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb7
.L_lambda_simple_env_end_3bb7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb7
.L_lambda_simple_params_end_3bb7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb7
	jmp .L_lambda_simple_end_3bb7
.L_lambda_simple_code_3bb7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb7:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e09:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e09
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e09
.L_tc_recycle_frame_done_4e09:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb7:	; new closure is in rax
	mov qword [free_var_88], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb8
.L_lambda_simple_env_end_3bb8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb8
.L_lambda_simple_params_end_3bb8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb8
	jmp .L_lambda_simple_end_3bb8
.L_lambda_simple_code_3bb8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb8:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0a
.L_tc_recycle_frame_done_4e0a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb8:	; new closure is in rax
	mov qword [free_var_89], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bb9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bb9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bb9
.L_lambda_simple_env_end_3bb9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bb9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bb9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bb9
.L_lambda_simple_params_end_3bb9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bb9
	jmp .L_lambda_simple_end_3bb9
.L_lambda_simple_code_3bb9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bb9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bb9:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0b
.L_tc_recycle_frame_done_4e0b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bb9:	; new closure is in rax
	mov qword [free_var_90], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bba:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bba
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bba
.L_lambda_simple_env_end_3bba:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bba:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bba
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bba
.L_lambda_simple_params_end_3bba:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bba
	jmp .L_lambda_simple_end_3bba
.L_lambda_simple_code_3bba:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bba
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bba:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0c
.L_tc_recycle_frame_done_4e0c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bba:	; new closure is in rax
	mov qword [free_var_91], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bbb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bbb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bbb
.L_lambda_simple_env_end_3bbb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bbb:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bbb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bbb
.L_lambda_simple_params_end_3bbb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bbb
	jmp .L_lambda_simple_end_3bbb
.L_lambda_simple_code_3bbb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bbb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bbb:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0d
.L_tc_recycle_frame_done_4e0d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bbb:	; new closure is in rax
	mov qword [free_var_92], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bbc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bbc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bbc
.L_lambda_simple_env_end_3bbc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bbc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bbc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bbc
.L_lambda_simple_params_end_3bbc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bbc
	jmp .L_lambda_simple_end_3bbc
.L_lambda_simple_code_3bbc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bbc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bbc:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0e
.L_tc_recycle_frame_done_4e0e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bbc:	; new closure is in rax
	mov qword [free_var_93], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bbd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bbd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bbd
.L_lambda_simple_env_end_3bbd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bbd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bbd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bbd
.L_lambda_simple_params_end_3bbd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bbd
	jmp .L_lambda_simple_end_3bbd
.L_lambda_simple_code_3bbd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bbd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bbd:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e0f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e0f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e0f
.L_tc_recycle_frame_done_4e0f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bbd:	; new closure is in rax
	mov qword [free_var_94], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bbe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bbe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bbe
.L_lambda_simple_env_end_3bbe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bbe:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bbe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bbe
.L_lambda_simple_params_end_3bbe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bbe
	jmp .L_lambda_simple_end_3bbe
.L_lambda_simple_code_3bbe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bbe
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bbe:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e10:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e10
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e10
.L_tc_recycle_frame_done_4e10:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bbe:	; new closure is in rax
	mov qword [free_var_95], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bbf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bbf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bbf
.L_lambda_simple_env_end_3bbf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bbf:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bbf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bbf
.L_lambda_simple_params_end_3bbf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bbf
	jmp .L_lambda_simple_end_3bbf
.L_lambda_simple_code_3bbf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bbf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bbf:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e11:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e11
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e11
.L_tc_recycle_frame_done_4e11:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bbf:	; new closure is in rax
	mov qword [free_var_96], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc0
.L_lambda_simple_env_end_3bc0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc0
.L_lambda_simple_params_end_3bc0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc0
	jmp .L_lambda_simple_end_3bc0
.L_lambda_simple_code_3bc0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e12:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e12
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e12
.L_tc_recycle_frame_done_4e12:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc0:	; new closure is in rax
	mov qword [free_var_97], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc1
.L_lambda_simple_env_end_3bc1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc1
.L_lambda_simple_params_end_3bc1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc1
	jmp .L_lambda_simple_end_3bc1
.L_lambda_simple_code_3bc1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e13:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e13
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e13
.L_tc_recycle_frame_done_4e13:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc1:	; new closure is in rax
	mov qword [free_var_98], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc2
.L_lambda_simple_env_end_3bc2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc2:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc2
.L_lambda_simple_params_end_3bc2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc2
	jmp .L_lambda_simple_end_3bc2
.L_lambda_simple_code_3bc2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc2
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc2:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_75]	; free var cadr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e14:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e14
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e14
.L_tc_recycle_frame_done_4e14:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc2:	; new closure is in rax
	mov qword [free_var_99], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc3
.L_lambda_simple_env_end_3bc3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc3
.L_lambda_simple_params_end_3bc3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc3
	jmp .L_lambda_simple_end_3bc3
.L_lambda_simple_code_3bc3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_76]	; free var cdar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e15:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e15
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e15
.L_tc_recycle_frame_done_4e15:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc3:	; new closure is in rax
	mov qword [free_var_100], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc4
.L_lambda_simple_env_end_3bc4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc4:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc4
.L_lambda_simple_params_end_3bc4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc4
	jmp .L_lambda_simple_end_3bc4
.L_lambda_simple_code_3bc4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_77]	; free var cddr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e16:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e16
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e16
.L_tc_recycle_frame_done_4e16:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc4:	; new closure is in rax
	mov qword [free_var_101], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc5
.L_lambda_simple_env_end_3bc5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc5
.L_lambda_simple_params_end_3bc5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc5
	jmp .L_lambda_simple_end_3bc5
.L_lambda_simple_code_3bc5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc5:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0406
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_524f
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e17:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e17
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e17
.L_tc_recycle_frame_done_4e17:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_524f
.L_if_else_524f:
	mov rax, L_constants + 2
.L_if_end_524f:
.L_or_end_0406:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc5:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08bc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_08bc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08bc
.L_lambda_opt_env_end_08bc:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08bc:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_08bc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08bc
.L_lambda_opt_params_end_08bc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08bc
	jmp .L_lambda_opt_end_08bc
.L_lambda_opt_code_08bc:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08bc
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08bc
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08bc:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2baa
.L_lambda_opt_stack_shrink_loop_2ba9:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2ba9
.L_lambda_opt_stack_shrink_loop_2baa:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bab:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bab
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08bc
.L_lambda_opt_stack_shrink_loop_2bac:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bac
jmp .L_lambda_opt_stack_adjusted_08bc
.L_lambda_opt_arity_check_exact_08bc:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2ba8:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08bc
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2ba8
.L_lambda_opt_stack_shrink_loop_exit_08bc:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08bc:
	enter 0, 0
	mov rax, PARAM(0)	; param args
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08bc:	; new closure is in rax
	mov qword [free_var_103], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc6
.L_lambda_simple_env_end_3bc6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc6
.L_lambda_simple_params_end_3bc6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc6
	jmp .L_lambda_simple_end_3bc6
.L_lambda_simple_code_3bc6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc6:
	enter 0, 0
	mov rax, PARAM(0)	; param x
	cmp rax, sob_boolean_false
	je .L_if_else_5250
	mov rax, L_constants + 2
	jmp .L_if_end_5250
.L_if_else_5250:
	mov rax, L_constants + 3
.L_if_end_5250:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc6:	; new closure is in rax
	mov qword [free_var_104], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc7
.L_lambda_simple_env_end_3bc7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc7:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc7
.L_lambda_simple_params_end_3bc7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc7
	jmp .L_lambda_simple_end_3bc7
.L_lambda_simple_code_3bc7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc7:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0407
	; preparing a tail-call
	mov rax, PARAM(0)	; param q
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e18:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e18
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e18
.L_tc_recycle_frame_done_4e18:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0407:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc7:	; new closure is in rax
	mov qword [free_var_105], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bc8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc8
.L_lambda_simple_env_end_3bc8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bc8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc8
.L_lambda_simple_params_end_3bc8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc8
	jmp .L_lambda_simple_end_3bc8
.L_lambda_simple_code_3bc8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bc8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc8:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bc9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bc9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bc9
.L_lambda_simple_env_end_3bc9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bc9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bc9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bc9
.L_lambda_simple_params_end_3bc9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bc9
	jmp .L_lambda_simple_end_3bc9
.L_lambda_simple_code_3bc9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bc9
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bc9:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5251
	mov rax, PARAM(0)	; param a
	jmp .L_if_end_5251
.L_if_else_5251:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e19:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e19
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e19
.L_tc_recycle_frame_done_4e19:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5251:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bc9:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08bd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08bd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08bd
.L_lambda_opt_env_end_08bd:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08bd:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08bd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08bd
.L_lambda_opt_params_end_08bd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08bd
	jmp .L_lambda_opt_end_08bd
.L_lambda_opt_code_08bd:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08bd
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08bd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08bd:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2baf
.L_lambda_opt_stack_shrink_loop_2bae:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bae
.L_lambda_opt_stack_shrink_loop_2baf:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bb0:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bb0
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08bd
.L_lambda_opt_stack_shrink_loop_2bb1:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bb1
jmp .L_lambda_opt_stack_adjusted_08bd
.L_lambda_opt_arity_check_exact_08bd:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bad:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08bd
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bad
.L_lambda_opt_stack_shrink_loop_exit_08bd:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08bd:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1a
.L_tc_recycle_frame_done_4e1a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08bd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bc8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_106], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bca
.L_lambda_simple_env_end_3bca:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bca:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bca
.L_lambda_simple_params_end_3bca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bca
	jmp .L_lambda_simple_end_3bca
.L_lambda_simple_code_3bca:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bca:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bcb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bcb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bcb
.L_lambda_simple_env_end_3bcb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bcb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bcb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bcb
.L_lambda_simple_params_end_3bcb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bcb
	jmp .L_lambda_simple_end_3bcb
.L_lambda_simple_code_3bcb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bcb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bcb:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5252
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1b
.L_tc_recycle_frame_done_4e1b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5252
.L_if_else_5252:
	mov rax, PARAM(0)	; param a
.L_if_end_5252:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bcb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08be:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08be
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08be
.L_lambda_opt_env_end_08be:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08be:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08be
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08be
.L_lambda_opt_params_end_08be:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08be
	jmp .L_lambda_opt_end_08be
.L_lambda_opt_code_08be:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08be
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08be
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08be:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bb4
.L_lambda_opt_stack_shrink_loop_2bb3:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bb3
.L_lambda_opt_stack_shrink_loop_2bb4:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bb5:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bb5
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08be
.L_lambda_opt_stack_shrink_loop_2bb6:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bb6
jmp .L_lambda_opt_stack_adjusted_08be
.L_lambda_opt_arity_check_exact_08be:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bb2:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08be
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bb2
.L_lambda_opt_stack_shrink_loop_exit_08be:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08be:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_29]	; free var __bin-apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1c
.L_tc_recycle_frame_done_4e1c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08be:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bca:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_107], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08bf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_08bf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08bf
.L_lambda_opt_env_end_08bf:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08bf:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_08bf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08bf
.L_lambda_opt_params_end_08bf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08bf
	jmp .L_lambda_opt_end_08bf
.L_lambda_opt_code_08bf:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08bf
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08bf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08bf:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bb9
.L_lambda_opt_stack_shrink_loop_2bb8:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bb8
.L_lambda_opt_stack_shrink_loop_2bb9:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bba:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bba
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08bf
.L_lambda_opt_stack_shrink_loop_2bbb:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bbb
jmp .L_lambda_opt_stack_adjusted_08bf
.L_lambda_opt_arity_check_exact_08bf:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bb7:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08bf
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bb7
.L_lambda_opt_stack_shrink_loop_exit_08bf:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08bf:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bcc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bcc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bcc
.L_lambda_simple_env_end_3bcc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bcc:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bcc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bcc
.L_lambda_simple_params_end_3bcc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bcc
	jmp .L_lambda_simple_end_3bcc
.L_lambda_simple_code_3bcc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bcc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bcc:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bcd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3bcd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bcd
.L_lambda_simple_env_end_3bcd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bcd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bcd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bcd
.L_lambda_simple_params_end_3bcd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bcd
	jmp .L_lambda_simple_end_3bcd
.L_lambda_simple_code_3bcd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bcd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bcd:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5253
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0408
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1d
.L_tc_recycle_frame_done_4e1d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_or_end_0408:
	jmp .L_if_end_5253
.L_if_else_5253:
	mov rax, L_constants + 2
.L_if_end_5253:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bcd:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1e
.L_tc_recycle_frame_done_4e1e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bcc:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e1f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e1f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e1f
.L_tc_recycle_frame_done_4e1f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08bf:	; new closure is in rax
	mov qword [free_var_108], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_08c0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c0
.L_lambda_opt_env_end_08c0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c0:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_08c0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c0
.L_lambda_opt_params_end_08c0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c0
	jmp .L_lambda_opt_end_08c0
.L_lambda_opt_code_08c0:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08c0
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08c0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c0:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bbe
.L_lambda_opt_stack_shrink_loop_2bbd:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bbd
.L_lambda_opt_stack_shrink_loop_2bbe:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bbf:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bbf
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c0
.L_lambda_opt_stack_shrink_loop_2bc0:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bc0
jmp .L_lambda_opt_stack_adjusted_08c0
.L_lambda_opt_arity_check_exact_08c0:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bbc:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c0
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bbc
.L_lambda_opt_stack_shrink_loop_exit_08c0:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c0:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bce
.L_lambda_simple_env_end_3bce:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bce:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bce
.L_lambda_simple_params_end_3bce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bce
	jmp .L_lambda_simple_end_3bce
.L_lambda_simple_code_3bce:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bce:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bcf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3bcf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bcf
.L_lambda_simple_env_end_3bcf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bcf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bcf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bcf
.L_lambda_simple_params_end_3bcf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bcf
	jmp .L_lambda_simple_end_3bcf
.L_lambda_simple_code_3bcf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bcf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bcf:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0409
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5254
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e20:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e20
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e20
.L_tc_recycle_frame_done_4e20:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5254
.L_if_else_5254:
	mov rax, L_constants + 2
.L_if_end_5254:
.L_or_end_0409:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bcf:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param loop
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var s
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param loop
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e21:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e21
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e21
.L_tc_recycle_frame_done_4e21:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bce:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e22:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e22
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e22
.L_tc_recycle_frame_done_4e22:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08c0:	; new closure is in rax
	mov qword [free_var_110], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bd0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd0
.L_lambda_simple_env_end_3bd0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bd0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd0
.L_lambda_simple_params_end_3bd0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd0
	jmp .L_lambda_simple_end_3bd0
.L_lambda_simple_code_3bd0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd0
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd0:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(1)
	mov [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd1
.L_lambda_simple_env_end_3bd1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd1:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bd1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd1
.L_lambda_simple_params_end_3bd1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd1
	jmp .L_lambda_simple_end_3bd1
.L_lambda_simple_code_3bd1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd1
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd1:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5255
	mov rax, L_constants + 1
	jmp .L_if_end_5255
.L_if_else_5255:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param f
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e23:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e23
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e23
.L_tc_recycle_frame_done_4e23:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5255:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd1:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param map1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd2
.L_lambda_simple_env_end_3bd2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd2:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bd2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd2
.L_lambda_simple_params_end_3bd2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd2
	jmp .L_lambda_simple_end_3bd2
.L_lambda_simple_code_3bd2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd2:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5256
	mov rax, L_constants + 1
	jmp .L_if_end_5256
.L_if_else_5256:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var map1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e24:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e24
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e24
.L_tc_recycle_frame_done_4e24:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5256:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd2:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param map-list
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08c1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c1
.L_lambda_opt_env_end_08c1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c1:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_08c1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c1
.L_lambda_opt_params_end_08c1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c1
	jmp .L_lambda_opt_end_08c1
.L_lambda_opt_code_08c1:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08c1
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08c1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c1:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bc3
.L_lambda_opt_stack_shrink_loop_2bc2:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bc2
.L_lambda_opt_stack_shrink_loop_2bc3:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bc4:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bc4
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c1
.L_lambda_opt_stack_shrink_loop_2bc5:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bc5
jmp .L_lambda_opt_stack_adjusted_08c1
.L_lambda_opt_arity_check_exact_08c1:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bc1:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c1
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bc1
.L_lambda_opt_stack_shrink_loop_exit_08c1:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c1:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5257
	mov rax, L_constants + 1
	jmp .L_if_end_5257
.L_if_else_5257:
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var map-list
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e25:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e25
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e25
.L_tc_recycle_frame_done_4e25:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5257:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08c1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_109], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bd3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd3
.L_lambda_simple_env_end_3bd3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd3:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bd3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd3
.L_lambda_simple_params_end_3bd3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd3
	jmp .L_lambda_simple_end_3bd3
.L_lambda_simple_code_3bd3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bd3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd3:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 1
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd4
.L_lambda_simple_env_end_3bd4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bd4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd4
.L_lambda_simple_params_end_3bd4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd4
	jmp .L_lambda_simple_end_3bd4
.L_lambda_simple_code_3bd4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param r
	push rax
	mov rax, PARAM(1)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e26:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e26
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e26
.L_tc_recycle_frame_done_4e26:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd4:	; new closure is in rax
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e27:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e27
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e27
.L_tc_recycle_frame_done_4e27:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bd3:	; new closure is in rax
	mov qword [free_var_111], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bd5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd5
.L_lambda_simple_env_end_3bd5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bd5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd5
.L_lambda_simple_params_end_3bd5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd5
	jmp .L_lambda_simple_end_3bd5
.L_lambda_simple_code_3bd5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd5
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd5:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(1)
	mov [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd6
.L_lambda_simple_env_end_3bd6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd6:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bd6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd6
.L_lambda_simple_params_end_3bd6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd6
	jmp .L_lambda_simple_end_3bd6
.L_lambda_simple_code_3bd6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd6:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5258
	mov rax, PARAM(0)	; param s1
	jmp .L_if_end_5258
.L_if_else_5258:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param sr
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param s1
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e28:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e28
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e28
.L_tc_recycle_frame_done_4e28:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5258:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd6:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run-1
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd7
.L_lambda_simple_env_end_3bd7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd7:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bd7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd7
.L_lambda_simple_params_end_3bd7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd7
	jmp .L_lambda_simple_end_3bd7
.L_lambda_simple_code_3bd7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bd7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd7:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5259
	mov rax, PARAM(1)	; param s2
	jmp .L_if_end_5259
.L_if_else_5259:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s2
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var run-2
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e29:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e29
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e29
.L_tc_recycle_frame_done_4e29:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5259:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd7:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param run-2
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08c2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c2
.L_lambda_opt_env_end_08c2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c2:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_08c2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c2
.L_lambda_opt_params_end_08c2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c2
	jmp .L_lambda_opt_end_08c2
.L_lambda_opt_code_08c2:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08c2
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08c2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c2:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bc8
.L_lambda_opt_stack_shrink_loop_2bc7:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bc7
.L_lambda_opt_stack_shrink_loop_2bc8:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bc9:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bc9
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c2
.L_lambda_opt_stack_shrink_loop_2bca:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bca
jmp .L_lambda_opt_stack_adjusted_08c2
.L_lambda_opt_arity_check_exact_08c2:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bc6:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c2
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bc6
.L_lambda_opt_stack_shrink_loop_exit_08c2:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c2:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525a
	mov rax, L_constants + 1
	jmp .L_if_end_525a
.L_if_else_525a:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run-1
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2a
.L_tc_recycle_frame_done_4e2a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_525a:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08c2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bd5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_113], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bd8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd8
.L_lambda_simple_env_end_3bd8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd8:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bd8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd8
.L_lambda_simple_params_end_3bd8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd8
	jmp .L_lambda_simple_end_3bd8
.L_lambda_simple_code_3bd8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bd8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd8:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bd9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bd9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bd9
.L_lambda_simple_env_end_3bd9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bd9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bd9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bd9
.L_lambda_simple_params_end_3bd9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bd9
	jmp .L_lambda_simple_end_3bd9
.L_lambda_simple_code_3bd9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3bd9
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bd9:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_108]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525b
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_525b
.L_if_else_525b:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2b
.L_tc_recycle_frame_done_4e2b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_525b:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3bd9:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08c3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c3
.L_lambda_opt_env_end_08c3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c3:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c3
.L_lambda_opt_params_end_08c3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c3
	jmp .L_lambda_opt_end_08c3
.L_lambda_opt_code_08c3:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_08c3
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_arity_check_more_08c3
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c3:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 2
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bcd
.L_lambda_opt_stack_shrink_loop_2bcc:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bcc
.L_lambda_opt_stack_shrink_loop_2bcd:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 2
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bce:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bce
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c3
.L_lambda_opt_stack_shrink_loop_2bcf:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bcf
jmp .L_lambda_opt_stack_adjusted_08c3
.L_lambda_opt_arity_check_exact_08c3:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 2]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bcb:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c3
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bcb
.L_lambda_opt_stack_shrink_loop_exit_08c3:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c3:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2c
.L_tc_recycle_frame_done_4e2c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_08c3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bd8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_112], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bda:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bda
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bda
.L_lambda_simple_env_end_3bda:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bda:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bda
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bda
.L_lambda_simple_params_end_3bda:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bda
	jmp .L_lambda_simple_end_3bda
.L_lambda_simple_code_3bda:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bda
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bda:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bdb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bdb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bdb
.L_lambda_simple_env_end_3bdb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bdb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bdb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bdb
.L_lambda_simple_params_end_3bdb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bdb
	jmp .L_lambda_simple_end_3bdb
.L_lambda_simple_code_3bdb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3bdb
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bdb:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_108]	; free var ormap
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525c
	mov rax, PARAM(1)	; param unit
	jmp .L_if_end_525c
.L_if_else_525c:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 1
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_113]	; free var append
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2d
.L_tc_recycle_frame_done_4e2d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_525c:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3bdb:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08c4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c4
.L_lambda_opt_env_end_08c4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c4:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c4
.L_lambda_opt_params_end_08c4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c4
	jmp .L_lambda_opt_end_08c4
.L_lambda_opt_code_08c4:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_opt_arity_check_exact_08c4
	cmp qword [rsp + 8 * 2], 2
	jg .L_lambda_opt_arity_check_more_08c4
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c4:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 2
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bd2
.L_lambda_opt_stack_shrink_loop_2bd1:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bd1
.L_lambda_opt_stack_shrink_loop_2bd2:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 2
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bd3:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bd3
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c4
.L_lambda_opt_stack_shrink_loop_2bd4:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bd4
jmp .L_lambda_opt_stack_adjusted_08c4
.L_lambda_opt_arity_check_exact_08c4:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 2]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bd0:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c4
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bd0
.L_lambda_opt_stack_shrink_loop_exit_08c4:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(2)	; param ss
	push rax
	mov rax, PARAM(1)	; param unit
	push rax
	mov rax, PARAM(0)	; param f
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2e
.L_tc_recycle_frame_done_4e2e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_opt_end_08c4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bda:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_114], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bdc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bdc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bdc
.L_lambda_simple_env_end_3bdc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bdc:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bdc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bdc
.L_lambda_simple_params_end_3bdc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bdc
	jmp .L_lambda_simple_end_3bdc
.L_lambda_simple_code_3bdc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3bdc
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bdc:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2066
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e2f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e2f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e2f
.L_tc_recycle_frame_done_4e2f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3bdc:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bdd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bdd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bdd
.L_lambda_simple_env_end_3bdd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bdd:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bdd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bdd
.L_lambda_simple_params_end_3bdd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bdd
	jmp .L_lambda_simple_end_3bdd
.L_lambda_simple_code_3bdd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bdd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bdd:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bde:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bde
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bde
.L_lambda_simple_env_end_3bde:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bde:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bde
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bde
.L_lambda_simple_params_end_3bde:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bde
	jmp .L_lambda_simple_end_3bde
.L_lambda_simple_code_3bde:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bde
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bde:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525d
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525e
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_38]	; free var __bin-add-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e30:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e30
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e30
.L_tc_recycle_frame_done_4e30:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_525e
.L_if_else_525e:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_525f
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e31:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e31
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e31
.L_tc_recycle_frame_done_4e31:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_525f
.L_if_else_525f:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5260
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e32:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e32
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e32
.L_tc_recycle_frame_done_4e32:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5260
.L_if_else_5260:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e33:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e33
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e33
.L_tc_recycle_frame_done_4e33:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5260:
.L_if_end_525f:
.L_if_end_525e:
	jmp .L_if_end_525d
.L_if_else_525d:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5261
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5262
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_116]	; free var __bin_integer_to_fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e34:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e34
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e34
.L_tc_recycle_frame_done_4e34:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5262
.L_if_else_5262:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5263
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_34]	; free var __bin-add-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e35:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e35
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e35
.L_tc_recycle_frame_done_4e35:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5263
.L_if_else_5263:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5264
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e36:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e36
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e36
.L_tc_recycle_frame_done_4e36:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5264
.L_if_else_5264:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e37:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e37
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e37
.L_tc_recycle_frame_done_4e37:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5264:
.L_if_end_5263:
.L_if_end_5262:
	jmp .L_if_end_5261
.L_if_else_5261:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5265
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5266
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e38:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e38
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e38
.L_tc_recycle_frame_done_4e38:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5266
.L_if_else_5266:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5267
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e39:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e39
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e39
.L_tc_recycle_frame_done_4e39:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5267
.L_if_else_5267:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5268
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_30]	; free var __bin-add-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3a
.L_tc_recycle_frame_done_4e3a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5268
.L_if_else_5268:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3b
.L_tc_recycle_frame_done_4e3b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5268:
.L_if_end_5267:
.L_if_end_5266:
	jmp .L_if_end_5265
.L_if_else_5265:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3c
.L_tc_recycle_frame_done_4e3c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5265:
.L_if_end_5261:
.L_if_end_525d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bde:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bdf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bdf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bdf
.L_lambda_simple_env_end_3bdf:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bdf:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bdf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bdf
.L_lambda_simple_params_end_3bdf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bdf
	jmp .L_lambda_simple_end_3bdf
.L_lambda_simple_code_3bdf:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bdf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bdf:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_08c5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c5
.L_lambda_opt_env_end_08c5:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c5:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c5
.L_lambda_opt_params_end_08c5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c5
	jmp .L_lambda_opt_end_08c5
.L_lambda_opt_code_08c5:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08c5
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08c5
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c5:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bd7
.L_lambda_opt_stack_shrink_loop_2bd6:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bd6
.L_lambda_opt_stack_shrink_loop_2bd7:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bd8:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bd8
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c5
.L_lambda_opt_stack_shrink_loop_2bd9:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bd9
jmp .L_lambda_opt_stack_adjusted_08c5
.L_lambda_opt_arity_check_exact_08c5:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bd5:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c5
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bd5
.L_lambda_opt_stack_shrink_loop_exit_08c5:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c5:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin+
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3d
.L_tc_recycle_frame_done_4e3d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08c5:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bdf:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3e
.L_tc_recycle_frame_done_4e3e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bdd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_115], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3be0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be0
.L_lambda_simple_env_end_3be0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3be0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be0
.L_lambda_simple_params_end_3be0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be0
	jmp .L_lambda_simple_end_3be0
.L_lambda_simple_code_3be0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3be0
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be0:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2139
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e3f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e3f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e3f
.L_tc_recycle_frame_done_4e3f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3be0:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3be1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be1
.L_lambda_simple_env_end_3be1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be1:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3be1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be1
.L_lambda_simple_params_end_3be1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be1
	jmp .L_lambda_simple_end_3be1
.L_lambda_simple_code_3be1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3be1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be1:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3be2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be2
.L_lambda_simple_env_end_3be2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be2:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3be2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be2
.L_lambda_simple_params_end_3be2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be2
	jmp .L_lambda_simple_end_3be2
.L_lambda_simple_code_3be2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3be2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be2:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5269
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526a
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_39]	; free var __bin-sub-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e40:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e40
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e40
.L_tc_recycle_frame_done_4e40:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_526a
.L_if_else_526a:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526b
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e41:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e41
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e41
.L_tc_recycle_frame_done_4e41:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_526b
.L_if_else_526b:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_118]	; free var real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526c
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e42:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e42
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e42
.L_tc_recycle_frame_done_4e42:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_526c
.L_if_else_526c:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e43:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e43
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e43
.L_tc_recycle_frame_done_4e43:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_526c:
.L_if_end_526b:
.L_if_end_526a:
	jmp .L_if_end_5269
.L_if_else_5269:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526d
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526e
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e44:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e44
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e44
.L_tc_recycle_frame_done_4e44:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_526e
.L_if_else_526e:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_526f
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_35]	; free var __bin-sub-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e45:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e45
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e45
.L_tc_recycle_frame_done_4e45:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_526f
.L_if_else_526f:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5270
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e46:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e46
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e46
.L_tc_recycle_frame_done_4e46:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5270
.L_if_else_5270:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e47:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e47
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e47
.L_tc_recycle_frame_done_4e47:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5270:
.L_if_end_526f:
.L_if_end_526e:
	jmp .L_if_end_526d
.L_if_else_526d:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5271
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5272
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e48:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e48
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e48
.L_tc_recycle_frame_done_4e48:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5272
.L_if_else_5272:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5273
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e49:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e49
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e49
.L_tc_recycle_frame_done_4e49:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5273
.L_if_else_5273:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5274
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_31]	; free var __bin-sub-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4a
.L_tc_recycle_frame_done_4e4a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5274
.L_if_else_5274:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4b
.L_tc_recycle_frame_done_4e4b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5274:
.L_if_end_5273:
.L_if_end_5272:
	jmp .L_if_end_5271
.L_if_else_5271:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4c
.L_tc_recycle_frame_done_4e4c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5271:
.L_if_end_526d:
.L_if_end_5269:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3be2:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3be3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be3
.L_lambda_simple_env_end_3be3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3be3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be3
.L_lambda_simple_params_end_3be3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be3
	jmp .L_lambda_simple_end_3be3
.L_lambda_simple_code_3be3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3be3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be3:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_08c6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c6
.L_lambda_opt_env_end_08c6:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c6:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c6
.L_lambda_opt_params_end_08c6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c6
	jmp .L_lambda_opt_end_08c6
.L_lambda_opt_code_08c6:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08c6
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08c6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c6:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bdc
.L_lambda_opt_stack_shrink_loop_2bdb:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bdb
.L_lambda_opt_stack_shrink_loop_2bdc:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bdd:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bdd
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c6
.L_lambda_opt_stack_shrink_loop_2bde:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bde
jmp .L_lambda_opt_stack_adjusted_08c6
.L_lambda_opt_arity_check_exact_08c6:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bda:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c6
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bda
.L_lambda_opt_stack_shrink_loop_exit_08c6:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c6:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5275
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2023
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4d
.L_tc_recycle_frame_done_4e4d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5275
.L_if_else_5275:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3be4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be4
.L_lambda_simple_env_end_3be4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be4:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3be4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be4
.L_lambda_simple_params_end_3be4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be4
	jmp .L_lambda_simple_end_3be4
.L_lambda_simple_code_3be4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3be4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4e
.L_tc_recycle_frame_done_4e4e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3be4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e4f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e4f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e4f
.L_tc_recycle_frame_done_4e4f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5275:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08c6:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3be3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e50:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e50
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e50
.L_tc_recycle_frame_done_4e50:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3be1:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_117], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3be5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be5
.L_lambda_simple_env_end_3be5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be5:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3be5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be5
.L_lambda_simple_params_end_3be5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be5
	jmp .L_lambda_simple_end_3be5
.L_lambda_simple_code_3be5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3be5
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be5:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2167
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e51:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e51
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e51
.L_tc_recycle_frame_done_4e51:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3be5:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3be6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be6
.L_lambda_simple_env_end_3be6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be6:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3be6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be6
.L_lambda_simple_params_end_3be6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be6
	jmp .L_lambda_simple_end_3be6
.L_lambda_simple_code_3be6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3be6
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be6:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3be7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be7
.L_lambda_simple_env_end_3be7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3be7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be7
.L_lambda_simple_params_end_3be7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be7
	jmp .L_lambda_simple_end_3be7
.L_lambda_simple_code_3be7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3be7
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be7:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5276
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5277
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_40]	; free var __bin-mul-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e52:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e52
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e52
.L_tc_recycle_frame_done_4e52:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5277
.L_if_else_5277:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5278
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e53:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e53
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e53
.L_tc_recycle_frame_done_4e53:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5278
.L_if_else_5278:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5279
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e54:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e54
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e54
.L_tc_recycle_frame_done_4e54:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5279
.L_if_else_5279:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e55:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e55
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e55
.L_tc_recycle_frame_done_4e55:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5279:
.L_if_end_5278:
.L_if_end_5277:
	jmp .L_if_end_5276
.L_if_else_5276:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527a
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527b
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e56:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e56
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e56
.L_tc_recycle_frame_done_4e56:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_527b
.L_if_else_527b:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527c
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_36]	; free var __bin-mul-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e57:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e57
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e57
.L_tc_recycle_frame_done_4e57:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_527c
.L_if_else_527c:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527d
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e58:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e58
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e58
.L_tc_recycle_frame_done_4e58:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_527d
.L_if_else_527d:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e59:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e59
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e59
.L_tc_recycle_frame_done_4e59:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_527d:
.L_if_end_527c:
.L_if_end_527b:
	jmp .L_if_end_527a
.L_if_else_527a:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527e
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_527f
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5a
.L_tc_recycle_frame_done_4e5a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_527f
.L_if_else_527f:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5280
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5b
.L_tc_recycle_frame_done_4e5b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5280
.L_if_else_5280:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5281
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_32]	; free var __bin-mul-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5c
.L_tc_recycle_frame_done_4e5c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5281
.L_if_else_5281:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5d
.L_tc_recycle_frame_done_4e5d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5281:
.L_if_end_5280:
.L_if_end_527f:
	jmp .L_if_end_527e
.L_if_else_527e:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5e
.L_tc_recycle_frame_done_4e5e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_527e:
.L_if_end_527a:
.L_if_end_5276:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3be7:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3be8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be8
.L_lambda_simple_env_end_3be8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3be8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be8
.L_lambda_simple_params_end_3be8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be8
	jmp .L_lambda_simple_end_3be8
.L_lambda_simple_code_3be8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3be8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be8:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_08c7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c7
.L_lambda_opt_env_end_08c7:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c7:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c7
.L_lambda_opt_params_end_08c7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c7
	jmp .L_lambda_opt_end_08c7
.L_lambda_opt_code_08c7:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08c7
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08c7
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c7:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2be1
.L_lambda_opt_stack_shrink_loop_2be0:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2be0
.L_lambda_opt_stack_shrink_loop_2be1:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2be2:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2be2
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c7
.L_lambda_opt_stack_shrink_loop_2be3:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2be3
jmp .L_lambda_opt_stack_adjusted_08c7
.L_lambda_opt_arity_check_exact_08c7:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bdf:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c7
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bdf
.L_lambda_opt_stack_shrink_loop_exit_08c7:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c7:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin*
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e5f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e5f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e5f
.L_tc_recycle_frame_done_4e5f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08c7:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3be8:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e60:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e60
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e60
.L_tc_recycle_frame_done_4e60:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3be6:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_119], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3be9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3be9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3be9
.L_lambda_simple_env_end_3be9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3be9:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3be9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3be9
.L_lambda_simple_params_end_3be9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3be9
	jmp .L_lambda_simple_end_3be9
.L_lambda_simple_code_3be9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3be9
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3be9:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2075
	push rax
	mov rax, L_constants + 2186
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e61:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e61
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e61
.L_tc_recycle_frame_done_4e61:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3be9:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bea:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bea
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bea
.L_lambda_simple_env_end_3bea:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bea:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bea
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bea
.L_lambda_simple_params_end_3bea:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bea
	jmp .L_lambda_simple_end_3bea
.L_lambda_simple_code_3bea:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bea
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bea:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3beb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3beb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3beb
.L_lambda_simple_env_end_3beb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3beb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3beb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3beb
.L_lambda_simple_params_end_3beb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3beb
	jmp .L_lambda_simple_end_3beb
.L_lambda_simple_code_3beb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3beb
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3beb:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5282
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5283
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_41]	; free var __bin-div-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e62:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e62
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e62
.L_tc_recycle_frame_done_4e62:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5283
.L_if_else_5283:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5284
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e63:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e63
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e63
.L_tc_recycle_frame_done_4e63:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5284
.L_if_else_5284:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5285
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e64:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e64
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e64
.L_tc_recycle_frame_done_4e64:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5285
.L_if_else_5285:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e65:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e65
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e65
.L_tc_recycle_frame_done_4e65:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5285:
.L_if_end_5284:
.L_if_end_5283:
	jmp .L_if_end_5282
.L_if_else_5282:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5286
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5287
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e66:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e66
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e66
.L_tc_recycle_frame_done_4e66:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5287
.L_if_else_5287:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5288
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_37]	; free var __bin-div-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e67:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e67
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e67
.L_tc_recycle_frame_done_4e67:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5288
.L_if_else_5288:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5289
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e68:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e68
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e68
.L_tc_recycle_frame_done_4e68:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5289
.L_if_else_5289:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e69:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e69
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e69
.L_tc_recycle_frame_done_4e69:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5289:
.L_if_end_5288:
.L_if_end_5287:
	jmp .L_if_end_5286
.L_if_else_5286:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528a
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528b
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6a
.L_tc_recycle_frame_done_4e6a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_528b
.L_if_else_528b:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528c
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6b
.L_tc_recycle_frame_done_4e6b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_528c
.L_if_else_528c:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528d
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_33]	; free var __bin-div-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6c
.L_tc_recycle_frame_done_4e6c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_528d
.L_if_else_528d:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6d
.L_tc_recycle_frame_done_4e6d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_528d:
.L_if_end_528c:
.L_if_end_528b:
	jmp .L_if_end_528a
.L_if_else_528a:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var error
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6e
.L_tc_recycle_frame_done_4e6e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_528a:
.L_if_end_5286:
.L_if_end_5282:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3beb:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bec:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bec
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bec
.L_lambda_simple_env_end_3bec:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bec:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bec
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bec
.L_lambda_simple_params_end_3bec:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bec
	jmp .L_lambda_simple_end_3bec
.L_lambda_simple_code_3bec:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bec
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bec:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_opt_env_end_08c8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c8
.L_lambda_opt_env_end_08c8:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c8:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c8
.L_lambda_opt_params_end_08c8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c8
	jmp .L_lambda_opt_end_08c8
.L_lambda_opt_code_08c8:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08c8
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08c8
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c8:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2be6
.L_lambda_opt_stack_shrink_loop_2be5:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2be5
.L_lambda_opt_stack_shrink_loop_2be6:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2be7:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2be7
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c8
.L_lambda_opt_stack_shrink_loop_2be8:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2be8
jmp .L_lambda_opt_stack_adjusted_08c8
.L_lambda_opt_arity_check_exact_08c8:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2be4:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c8
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2be4
.L_lambda_opt_stack_shrink_loop_exit_08c8:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c8:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528e
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, L_constants + 2158
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e6f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e6f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e6f
.L_tc_recycle_frame_done_4e6f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_528e
.L_if_else_528e:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, L_constants + 2158
	push rax
	mov rax, qword [free_var_119]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, qword [free_var_112]	; free var fold-left
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bed:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3bed
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bed
.L_lambda_simple_env_end_3bed:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bed:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3bed
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bed
.L_lambda_simple_params_end_3bed:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bed
	jmp .L_lambda_simple_end_3bed
.L_lambda_simple_code_3bed:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bed
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bed:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param b
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin/
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e70:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e70
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e70
.L_tc_recycle_frame_done_4e70:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bed:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e71:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e71
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e71
.L_tc_recycle_frame_done_4e71:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_528e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08c8:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bec:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e72:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e72
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e72
.L_tc_recycle_frame_done_4e72:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bea:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_120], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bee:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bee
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bee
.L_lambda_simple_env_end_3bee:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bee:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bee
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bee
.L_lambda_simple_params_end_3bee:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bee
	jmp .L_lambda_simple_end_3bee
.L_lambda_simple_code_3bee:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bee
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bee:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_528f
	mov rax, L_constants + 2158
	jmp .L_if_end_528f
.L_if_else_528f:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_121]	; free var fact
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_119]	; free var *
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e73:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e73
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e73
.L_tc_recycle_frame_done_4e73:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_528f:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bee:	; new closure is in rax
	mov qword [free_var_121], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_122], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_123], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_124], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_125], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_126], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bef:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bef
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bef
.L_lambda_simple_env_end_3bef:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bef:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bef
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bef
.L_lambda_simple_params_end_3bef:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bef
	jmp .L_lambda_simple_end_3bef
.L_lambda_simple_code_3bef:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3bef
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bef:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2296
	push rax
	mov rax, L_constants + 2287
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e74:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e74
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e74
.L_tc_recycle_frame_done_4e74:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3bef:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3bf0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf0
.L_lambda_simple_env_end_3bf0:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf0:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3bf0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf0
.L_lambda_simple_params_end_3bf0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf0
	jmp .L_lambda_simple_end_3bf0
.L_lambda_simple_code_3bf0:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf0:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bf1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf1
.L_lambda_simple_env_end_3bf1:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf1:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf1
.L_lambda_simple_params_end_3bf1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf1
	jmp .L_lambda_simple_end_3bf1
.L_lambda_simple_code_3bf1:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3bf1
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf1:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3bf2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf2
.L_lambda_simple_env_end_3bf2:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf2:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_3bf2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf2
.L_lambda_simple_params_end_3bf2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf2
	jmp .L_lambda_simple_end_3bf2
.L_lambda_simple_code_3bf2:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bf2
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf2:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5290
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5291
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator-zz
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e75:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e75
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e75
.L_tc_recycle_frame_done_4e75:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5291
.L_if_else_5291:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5292
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e76:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e76
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e76
.L_tc_recycle_frame_done_4e76:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5292
.L_if_else_5292:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5293
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e77:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e77
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e77
.L_tc_recycle_frame_done_4e77:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5293
.L_if_else_5293:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e78:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e78
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e78
.L_tc_recycle_frame_done_4e78:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5293:
.L_if_end_5292:
.L_if_end_5291:
	jmp .L_if_end_5290
.L_if_else_5290:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5294
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5295
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_62]	; free var __integer-to-fraction
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e79:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e79
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e79
.L_tc_recycle_frame_done_4e79:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5295
.L_if_else_5295:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5296
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var comparator-qq
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7a
.L_tc_recycle_frame_done_4e7a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5296
.L_if_else_5296:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5297
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7b
.L_tc_recycle_frame_done_4e7b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5297
.L_if_else_5297:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7c
.L_tc_recycle_frame_done_4e7c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5297:
.L_if_end_5296:
.L_if_end_5295:
	jmp .L_if_end_5294
.L_if_else_5294:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5298
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_28]	; free var integer?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_5299
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_22]	; free var integer->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7d
.L_tc_recycle_frame_done_4e7d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_5299
.L_if_else_5299:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_9]	; free var fraction?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_529a
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_23]	; free var fraction->real
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7e
.L_tc_recycle_frame_done_4e7e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_529a
.L_if_else_529a:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	push 1	; arg count
	mov rax, qword [free_var_8]	; free var real?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_529b
	; preparing a tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var comparator-rr
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e7f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e7f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e7f
.L_tc_recycle_frame_done_4e7f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_529b
.L_if_else_529b:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e80:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e80
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e80
.L_tc_recycle_frame_done_4e80:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_529b:
.L_if_end_529a:
.L_if_end_5299:
	jmp .L_if_end_5298
.L_if_else_5298:
	; preparing a tail-call
	push 0	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var exit
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 0 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e81:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e81
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e81
.L_tc_recycle_frame_done_4e81:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_5298:
.L_if_end_5294:
.L_if_end_5290:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bf2:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3bf1:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3bf3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf3
.L_lambda_simple_env_end_3bf3:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf3:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf3
.L_lambda_simple_params_end_3bf3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf3
	jmp .L_lambda_simple_end_3bf3
.L_lambda_simple_code_3bf3:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf3
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf3:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, qword [free_var_43]	; free var __bin-less-than-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_44]	; free var __bin-less-than-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_45]	; free var __bin-less-than-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, PARAM(0)	; param make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3bf4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf4
.L_lambda_simple_env_end_3bf4:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf4:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf4
.L_lambda_simple_params_end_3bf4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf4
	jmp .L_lambda_simple_end_3bf4
.L_lambda_simple_code_3bf4:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf4
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf4:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, qword [free_var_46]	; free var __bin-equal-rr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_47]	; free var __bin-equal-qq
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_48]	; free var __bin-equal-zz
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var make-bin-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf5:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3bf5
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf5
.L_lambda_simple_env_end_3bf5:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf5:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf5
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf5
.L_lambda_simple_params_end_3bf5:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf5
	jmp .L_lambda_simple_end_3bf5
.L_lambda_simple_code_3bf5:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf5
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf5:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf6:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_3bf6
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf6
.L_lambda_simple_env_end_3bf6:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf6:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf6
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf6
.L_lambda_simple_params_end_3bf6:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf6
	jmp .L_lambda_simple_end_3bf6
.L_lambda_simple_code_3bf6:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bf6
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf6:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e82:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e82
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e82
.L_tc_recycle_frame_done_4e82:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bf6:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf7:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_3bf7
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf7
.L_lambda_simple_env_end_3bf7:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf7:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf7
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf7
.L_lambda_simple_params_end_3bf7:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf7
	jmp .L_lambda_simple_end_3bf7
.L_lambda_simple_code_3bf7:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf7
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf7:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf8:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_3bf8
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf8
.L_lambda_simple_env_end_3bf8:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf8:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf8
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf8
.L_lambda_simple_params_end_3bf8:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf8
	jmp .L_lambda_simple_end_3bf8
.L_lambda_simple_code_3bf8:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bf8
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf8:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e83:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e83
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e83
.L_tc_recycle_frame_done_4e83:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bf8:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 6	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bf9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 5
	je .L_lambda_simple_env_end_3bf9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bf9
.L_lambda_simple_env_end_3bf9:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bf9:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bf9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bf9
.L_lambda_simple_params_end_3bf9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bf9
	jmp .L_lambda_simple_end_3bf9
.L_lambda_simple_code_3bf9:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bf9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bf9:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bfa:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_3bfa
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bfa
.L_lambda_simple_env_end_3bfa:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bfa:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bfa
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bfa
.L_lambda_simple_params_end_3bfa:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bfa
	jmp .L_lambda_simple_end_3bfa
.L_lambda_simple_code_3bfa:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bfa
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bfa:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e84:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e84
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e84
.L_tc_recycle_frame_done_4e84:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bfa:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 7	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bfb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 6
	je .L_lambda_simple_env_end_3bfb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bfb
.L_lambda_simple_env_end_3bfb:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bfb:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bfb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bfb
.L_lambda_simple_params_end_3bfb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bfb
	jmp .L_lambda_simple_end_3bfb
.L_lambda_simple_code_3bfb:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bfb
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bfb:
	enter 0, 0
	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bfc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_3bfc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bfc
.L_lambda_simple_env_end_3bfc:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bfc:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bfc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bfc
.L_lambda_simple_params_end_3bfc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bfc
	jmp .L_lambda_simple_end_3bfc
.L_lambda_simple_code_3bfc:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bfc
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bfc:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 9	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bfd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 8
	je .L_lambda_simple_env_end_3bfd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bfd
.L_lambda_simple_env_end_3bfd:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bfd:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bfd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bfd
.L_lambda_simple_params_end_3bfd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bfd
	jmp .L_lambda_simple_end_3bfd
.L_lambda_simple_code_3bfd:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bfd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bfd:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bfe:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_simple_env_end_3bfe
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bfe
.L_lambda_simple_env_end_3bfe:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bfe:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bfe
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bfe
.L_lambda_simple_params_end_3bfe:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bfe
	jmp .L_lambda_simple_end_3bfe
.L_lambda_simple_code_3bfe:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3bfe
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bfe:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040a
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin-ordering
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_529c
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e85:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e85
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e85
.L_tc_recycle_frame_done_4e85:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_529c
.L_if_else_529c:
	mov rax, L_constants + 2
.L_if_end_529c:
.L_or_end_040a:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3bfe:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 10	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08c9:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 9
	je .L_lambda_opt_env_end_08c9
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08c9
.L_lambda_opt_env_end_08c9:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08c9:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08c9
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08c9
.L_lambda_opt_params_end_08c9:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08c9
	jmp .L_lambda_opt_end_08c9
.L_lambda_opt_code_08c9:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08c9
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08c9
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08c9:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2beb
.L_lambda_opt_stack_shrink_loop_2bea:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bea
.L_lambda_opt_stack_shrink_loop_2beb:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bec:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bec
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08c9
.L_lambda_opt_stack_shrink_loop_2bed:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bed
jmp .L_lambda_opt_stack_adjusted_08c9
.L_lambda_opt_arity_check_exact_08c9:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2be9:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08c9
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2be9
.L_lambda_opt_stack_shrink_loop_exit_08c9:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08c9:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e86:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e86
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e86
.L_tc_recycle_frame_done_4e86:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08c9:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bfd:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e87:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e87
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e87
.L_tc_recycle_frame_done_4e87:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bfc:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 8	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3bff:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 7
	je .L_lambda_simple_env_end_3bff
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3bff
.L_lambda_simple_env_end_3bff:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3bff:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3bff
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3bff
.L_lambda_simple_params_end_3bff:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3bff
	jmp .L_lambda_simple_end_3bff
.L_lambda_simple_code_3bff:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3bff
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3bff:
	enter 0, 0
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 4]
	mov rax, qword [rax + 8 * 0]	; bound var bin<?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_122], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var bin<=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_123], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var bin>?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_124], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var bin>=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_125], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 3]
	mov rax, qword [rax + 8 * 0]	; bound var bin=?
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-run
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_126], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bff:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e88:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e88
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e88
.L_tc_recycle_frame_done_4e88:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bfb:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e89:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e89
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e89
.L_tc_recycle_frame_done_4e89:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf9:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8a
.L_tc_recycle_frame_done_4e8a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf7:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8b
.L_tc_recycle_frame_done_4e8b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf5:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8c
.L_tc_recycle_frame_done_4e8c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf4:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8d
.L_tc_recycle_frame_done_4e8d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf3:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8e
.L_tc_recycle_frame_done_4e8e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3bf0:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c00:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c00
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c00
.L_lambda_simple_env_end_3c00:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c00:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c00
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c00
.L_lambda_simple_params_end_3c00:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c00
	jmp .L_lambda_simple_end_3c00
.L_lambda_simple_code_3c00:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c00
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c00:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c01:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c01
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c01
.L_lambda_simple_env_end_3c01:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c01:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c01
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c01
.L_lambda_simple_params_end_3c01:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c01
	jmp .L_lambda_simple_end_3c01
.L_lambda_simple_code_3c01:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c01
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c01:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_529d
	mov rax, L_constants + 1
	jmp .L_if_end_529d
.L_if_else_529d:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param ch
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param ch
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e8f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e8f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e8f
.L_tc_recycle_frame_done_4e8f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_529d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c01:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08ca:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08ca
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08ca
.L_lambda_opt_env_end_08ca:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08ca:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08ca
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08ca
.L_lambda_opt_params_end_08ca:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08ca
	jmp .L_lambda_opt_end_08ca
.L_lambda_opt_code_08ca:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08ca
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08ca
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08ca:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bf0
.L_lambda_opt_stack_shrink_loop_2bef:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bef
.L_lambda_opt_stack_shrink_loop_2bf0:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bf1:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bf1
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08ca
.L_lambda_opt_stack_shrink_loop_2bf2:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bf2
jmp .L_lambda_opt_stack_adjusted_08ca
.L_lambda_opt_arity_check_exact_08ca:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bee:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08ca
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bee
.L_lambda_opt_stack_shrink_loop_exit_08ca:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08ca:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_529e
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e90:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e90
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e90
.L_tc_recycle_frame_done_4e90:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_529e
.L_if_else_529e:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a0
.L_if_else_52a0:
	mov rax, L_constants + 2
.L_if_end_52a0:
	cmp rax, sob_boolean_false
	je .L_if_else_529f
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e91:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e91
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e91
.L_tc_recycle_frame_done_4e91:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_529f
.L_if_else_529f:
	; preparing a tail-call
	mov rax, L_constants + 2365
	push rax
	mov rax, L_constants + 2356
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e92:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e92
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e92
.L_tc_recycle_frame_done_4e92:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_529f:
.L_if_end_529e:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08ca:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c00:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_127], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_128], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_129], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_130], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_131], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_132], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c02:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c02
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c02
.L_lambda_simple_env_end_3c02:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c02:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c02
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c02
.L_lambda_simple_params_end_3c02:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c02
	jmp .L_lambda_simple_end_3c02
.L_lambda_simple_code_3c02:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c02
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c02:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08cb:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08cb
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08cb
.L_lambda_opt_env_end_08cb:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08cb:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08cb
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08cb
.L_lambda_opt_params_end_08cb:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08cb
	jmp .L_lambda_opt_end_08cb
.L_lambda_opt_code_08cb:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08cb
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08cb
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08cb:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bf5
.L_lambda_opt_stack_shrink_loop_2bf4:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bf4
.L_lambda_opt_stack_shrink_loop_2bf5:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bf6:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bf6
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08cb
.L_lambda_opt_stack_shrink_loop_2bf7:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bf7
jmp .L_lambda_opt_stack_adjusted_08cb
.L_lambda_opt_arity_check_exact_08cb:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bf3:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08cb
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bf3
.L_lambda_opt_stack_shrink_loop_exit_08cb:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08cb:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e93:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e93
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e93
.L_tc_recycle_frame_done_4e93:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08cb:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c02:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c03:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c03
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c03
.L_lambda_simple_env_end_3c03:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c03:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c03
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c03
.L_lambda_simple_params_end_3c03:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c03
	jmp .L_lambda_simple_end_3c03
.L_lambda_simple_code_3c03:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c03
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c03:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_128], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_129], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_130], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_124]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_131], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_125]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_132], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c03:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_134], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2538
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2542
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c04:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c04
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c04
.L_lambda_simple_env_end_3c04:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c04:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c04
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c04
.L_lambda_simple_params_end_3c04:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c04
	jmp .L_lambda_simple_end_3c04
.L_lambda_simple_code_3c04:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c04
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c04:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c05:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c05
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c05
.L_lambda_simple_env_end_3c05:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c05:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c05
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c05
.L_lambda_simple_params_end_3c05:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c05
	jmp .L_lambda_simple_end_3c05
.L_lambda_simple_code_3c05:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c05
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c05:
	enter 0, 0
	; preparing a non tail-call
	mov rax, L_constants + 2540
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2538
	push rax
	push 3	; arg count
	mov rax, qword [free_var_129]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a1
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_25]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e94:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e94
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e94
.L_tc_recycle_frame_done_4e94:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a1
.L_if_else_52a1:
	mov rax, PARAM(0)	; param ch
.L_if_end_52a1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c05:	; new closure is in rax
	mov qword [free_var_133], rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c06:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c06
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c06
.L_lambda_simple_env_end_3c06:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c06:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c06
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c06
.L_lambda_simple_params_end_3c06:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c06
	jmp .L_lambda_simple_end_3c06
.L_lambda_simple_code_3c06:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c06
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c06:
	enter 0, 0
	; preparing a non tail-call
	mov rax, L_constants + 2544
	push rax
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, L_constants + 2542
	push rax
	push 3	; arg count
	mov rax, qword [free_var_129]	; free var char<=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a2
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var delta
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_25]	; free var integer->char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e95:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e95
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e95
.L_tc_recycle_frame_done_4e95:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a2
.L_if_else_52a2:
	mov rax, PARAM(0)	; param ch
.L_if_end_52a2:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c06:	; new closure is in rax
	mov qword [free_var_134], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c04:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_135], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_136], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_137], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_138], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_139], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c07:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c07
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c07
.L_lambda_simple_env_end_3c07:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c07:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c07
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c07
.L_lambda_simple_params_end_3c07:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c07
	jmp .L_lambda_simple_end_3c07
.L_lambda_simple_code_3c07:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c07
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c07:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08cc:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08cc
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08cc
.L_lambda_opt_env_end_08cc:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08cc:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08cc
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08cc
.L_lambda_opt_params_end_08cc:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08cc
	jmp .L_lambda_opt_end_08cc
.L_lambda_opt_code_08cc:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08cc
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08cc
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08cc:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bfa
.L_lambda_opt_stack_shrink_loop_2bf9:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bf9
.L_lambda_opt_stack_shrink_loop_2bfa:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2bfb:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2bfb
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08cc
.L_lambda_opt_stack_shrink_loop_2bfc:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2bfc
jmp .L_lambda_opt_stack_adjusted_08cc
.L_lambda_opt_arity_check_exact_08cc:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bf8:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08cc
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bf8
.L_lambda_opt_stack_shrink_loop_exit_08cc:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08cc:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c08:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c08
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c08
.L_lambda_simple_env_end_3c08:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c08:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c08
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c08
.L_lambda_simple_params_end_3c08:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c08
	jmp .L_lambda_simple_end_3c08
.L_lambda_simple_code_3c08:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c08
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c08:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	push 1	; arg count
	mov rax, qword [free_var_133]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_24]	; free var char->integer
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e96:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e96
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e96
.L_tc_recycle_frame_done_4e96:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c08:	; new closure is in rax
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var comparator
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e97:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e97
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e97
.L_tc_recycle_frame_done_4e97:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08cc:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c07:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c09:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c09
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c09
.L_lambda_simple_env_end_3c09:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c09:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c09
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c09
.L_lambda_simple_params_end_3c09:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c09
	jmp .L_lambda_simple_end_3c09
.L_lambda_simple_code_3c09:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c09
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c09:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_135], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_136], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_137], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_124]	; free var >
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_138], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_125]	; free var >=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-char-ci-comparator
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_139], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c09:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_140], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_141], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c0a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0a
.L_lambda_simple_env_end_3c0a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c0a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0a
.L_lambda_simple_params_end_3c0a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0a
	jmp .L_lambda_simple_end_3c0a
.L_lambda_simple_code_3c0a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c0a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0a:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c0b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0b
.L_lambda_simple_env_end_3c0b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c0b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0b
.L_lambda_simple_params_end_3c0b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0b
	jmp .L_lambda_simple_end_3c0b
.L_lambda_simple_code_3c0b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c0b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var char-case-converter
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e98:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e98
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e98
.L_tc_recycle_frame_done_4e98:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c0b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c0a:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c0c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0c
.L_lambda_simple_env_end_3c0c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c0c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0c
.L_lambda_simple_params_end_3c0c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0c
	jmp .L_lambda_simple_end_3c0c
.L_lambda_simple_code_3c0c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c0c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0c:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_133]	; free var char-downcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_140], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_134]	; free var char-upcase
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string-case-converter
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_141], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c0c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_144], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_145], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_146], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_147], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_148], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_149], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_150], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_151], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_152], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 0
	mov qword [free_var_153], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c0d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0d
.L_lambda_simple_env_end_3c0d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c0d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0d
.L_lambda_simple_params_end_3c0d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0d
	jmp .L_lambda_simple_end_3c0d
.L_lambda_simple_code_3c0d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c0d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0d:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c0e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0e
.L_lambda_simple_env_end_3c0e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0e:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c0e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0e
.L_lambda_simple_params_end_3c0e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0e
	jmp .L_lambda_simple_end_3c0e
.L_lambda_simple_code_3c0e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c0e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0e:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c0f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c0f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c0f
.L_lambda_simple_env_end_3c0f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c0f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c0f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c0f
.L_lambda_simple_params_end_3c0f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c0f
	jmp .L_lambda_simple_end_3c0f
.L_lambda_simple_code_3c0f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_3c0f
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c0f:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a3
	; preparing a non tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a3
.L_if_else_52a3:
	mov rax, L_constants + 2
.L_if_end_52a3:
	cmp rax, sob_boolean_false
	jne .L_or_end_040b
	; preparing a non tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a4
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040c
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a5
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e99:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e99
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e99
.L_tc_recycle_frame_done_4e99:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a5
.L_if_else_52a5:
	mov rax, L_constants + 2
.L_if_end_52a5:
.L_or_end_040c:
	jmp .L_if_end_52a4
.L_if_else_52a4:
	mov rax, L_constants + 2
.L_if_end_52a4:
.L_or_end_040b:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_3c0f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c10:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c10
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c10
.L_lambda_simple_env_end_3c10:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c10:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c10
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c10
.L_lambda_simple_params_end_3c10:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c10
	jmp .L_lambda_simple_end_3c10
.L_lambda_simple_code_3c10:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c10
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c10:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c11:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c11
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c11
.L_lambda_simple_env_end_3c11:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c11:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c11
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c11
.L_lambda_simple_params_end_3c11:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c11
	jmp .L_lambda_simple_end_3c11
.L_lambda_simple_code_3c11:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c11
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c11:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a6
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9a:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9a
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9a
.L_tc_recycle_frame_done_4e9a:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a6
.L_if_else_52a6:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9b:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9b
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9b
.L_tc_recycle_frame_done_4e9b:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52a6:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c11:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9c:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9c
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9c
.L_tc_recycle_frame_done_4e9c:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c10:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c12:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c12
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c12
.L_lambda_simple_env_end_3c12:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c12:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c12
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c12
.L_lambda_simple_params_end_3c12:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c12
	jmp .L_lambda_simple_end_3c12
.L_lambda_simple_code_3c12:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c12
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c12:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c13:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c13
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c13
.L_lambda_simple_env_end_3c13:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c13:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c13
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c13
.L_lambda_simple_params_end_3c13:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c13
	jmp .L_lambda_simple_end_3c13
.L_lambda_simple_code_3c13:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c13
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c13:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c14:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_3c14
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c14
.L_lambda_simple_env_end_3c14:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c14:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c14
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c14
.L_lambda_simple_params_end_3c14:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c14
	jmp .L_lambda_simple_end_3c14
.L_lambda_simple_code_3c14:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c14
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c14:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040d
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a7
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9d:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9d
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9d
.L_tc_recycle_frame_done_4e9d:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a7
.L_if_else_52a7:
	mov rax, L_constants + 2
.L_if_end_52a7:
.L_or_end_040d:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c14:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08cd:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_08cd
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08cd
.L_lambda_opt_env_end_08cd:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08cd:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08cd
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08cd
.L_lambda_opt_params_end_08cd:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08cd
	jmp .L_lambda_opt_end_08cd
.L_lambda_opt_code_08cd:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08cd
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08cd
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08cd:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2bff
.L_lambda_opt_stack_shrink_loop_2bfe:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2bfe
.L_lambda_opt_stack_shrink_loop_2bff:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c00:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c00
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08cd
.L_lambda_opt_stack_shrink_loop_2c01:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c01
jmp .L_lambda_opt_stack_adjusted_08cd
.L_lambda_opt_arity_check_exact_08cd:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2bfd:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08cd
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2bfd
.L_lambda_opt_stack_shrink_loop_exit_08cd:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08cd:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9e:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9e
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9e
.L_tc_recycle_frame_done_4e9e:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08cd:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c13:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4e9f:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4e9f
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4e9f
.L_tc_recycle_frame_done_4e9f:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c12:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea0
.L_tc_recycle_frame_done_4ea0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c0e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea1
.L_tc_recycle_frame_done_4ea1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c0d:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c15:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c15
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c15
.L_lambda_simple_env_end_3c15:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c15:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c15
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c15
.L_lambda_simple_params_end_3c15:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c15
	jmp .L_lambda_simple_end_3c15
.L_lambda_simple_code_3c15:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c15
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c15:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_128]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_144], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_135]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_149], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_131]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_148], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_138]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_153], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c15:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c16:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c16
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c16
.L_lambda_simple_env_end_3c16:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c16:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c16
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c16
.L_lambda_simple_params_end_3c16:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c16
	jmp .L_lambda_simple_end_3c16
.L_lambda_simple_code_3c16:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c16
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c16:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c17:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c17
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c17
.L_lambda_simple_env_end_3c17:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c17:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c17
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c17
.L_lambda_simple_params_end_3c17:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c17
	jmp .L_lambda_simple_end_3c17
.L_lambda_simple_code_3c17:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c17
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c17:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c18:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c18
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c18
.L_lambda_simple_env_end_3c18:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c18:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c18
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c18
.L_lambda_simple_params_end_3c18:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c18
	jmp .L_lambda_simple_end_3c18
.L_lambda_simple_code_3c18:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_3c18
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c18:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040e
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char<?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040e
	; preparing a non tail-call
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a8
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52a9
	; preparing a tail-call
	mov rax, PARAM(4)	; param len2
	push rax
	mov rax, PARAM(3)	; param str2
	push rax
	mov rax, PARAM(2)	; param len1
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea2
.L_tc_recycle_frame_done_4ea2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52a9
.L_if_else_52a9:
	mov rax, L_constants + 2
.L_if_end_52a9:
	jmp .L_if_end_52a8
.L_if_else_52a8:
	mov rax, L_constants + 2
.L_if_end_52a8:
.L_or_end_040e:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_3c18:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c19:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c19
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c19
.L_lambda_simple_env_end_3c19:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c19:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c19
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c19
.L_lambda_simple_params_end_3c19:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c19
	jmp .L_lambda_simple_end_3c19
.L_lambda_simple_code_3c19:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c19
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c19:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c1a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1a
.L_lambda_simple_env_end_3c1a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1a:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c1a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1a
.L_lambda_simple_params_end_3c1a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1a
	jmp .L_lambda_simple_end_3c1a
.L_lambda_simple_code_3c1a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c1a
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1a:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_123]	; free var <=
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52aa
	; preparing a tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea3
.L_tc_recycle_frame_done_4ea3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52aa
.L_if_else_52aa:
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, L_constants + 2023
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea4
.L_tc_recycle_frame_done_4ea4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52aa:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c1a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea5
.L_tc_recycle_frame_done_4ea5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c19:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c1b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1b
.L_lambda_simple_env_end_3c1b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c1b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1b
.L_lambda_simple_params_end_3c1b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1b
	jmp .L_lambda_simple_end_3c1b
.L_lambda_simple_code_3c1b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c1b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1b:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c1c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1c
.L_lambda_simple_env_end_3c1c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1c:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c1c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1c
.L_lambda_simple_params_end_3c1c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1c
	jmp .L_lambda_simple_end_3c1c
.L_lambda_simple_code_3c1c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c1c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1c:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_3c1d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1d
.L_lambda_simple_env_end_3c1d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c1d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1d
.L_lambda_simple_params_end_3c1d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1d
	jmp .L_lambda_simple_end_3c1d
.L_lambda_simple_code_3c1d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c1d
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1d:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_040f
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ab
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea6
.L_tc_recycle_frame_done_4ea6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52ab
.L_if_else_52ab:
	mov rax, L_constants + 2
.L_if_end_52ab:
.L_or_end_040f:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c1d:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08ce:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_08ce
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08ce
.L_lambda_opt_env_end_08ce:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08ce:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08ce
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08ce
.L_lambda_opt_params_end_08ce:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08ce
	jmp .L_lambda_opt_end_08ce
.L_lambda_opt_code_08ce:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08ce
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08ce
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08ce:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c04
.L_lambda_opt_stack_shrink_loop_2c03:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c03
.L_lambda_opt_stack_shrink_loop_2c04:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c05:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c05
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08ce
.L_lambda_opt_stack_shrink_loop_2c06:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c06
jmp .L_lambda_opt_stack_adjusted_08ce
.L_lambda_opt_arity_check_exact_08ce:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c02:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08ce
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c02
.L_lambda_opt_stack_shrink_loop_exit_08ce:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08ce:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea7
.L_tc_recycle_frame_done_4ea7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08ce:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c1c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea8
.L_tc_recycle_frame_done_4ea8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c1b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ea9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ea9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ea9
.L_tc_recycle_frame_done_4ea9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c17:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eaa:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eaa
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eaa
.L_tc_recycle_frame_done_4eaa:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c16:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c1e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1e
.L_lambda_simple_env_end_3c1e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c1e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1e
.L_lambda_simple_params_end_3c1e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1e
	jmp .L_lambda_simple_end_3c1e
.L_lambda_simple_code_3c1e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c1e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1e:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_128]	; free var char<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_145], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_135]	; free var char-ci<?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_150], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_131]	; free var char>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_147], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	mov rax, qword [free_var_138]	; free var char-ci>?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, PARAM(0)	; param make-string<=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_152], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c1e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c1f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c1f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c1f
.L_lambda_simple_env_end_3c1f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c1f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c1f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c1f
.L_lambda_simple_params_end_3c1f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c1f
	jmp .L_lambda_simple_end_3c1f
.L_lambda_simple_code_3c1f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c1f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c1f:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c20:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c20
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c20
.L_lambda_simple_env_end_3c20:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c20:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c20
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c20
.L_lambda_simple_params_end_3c20:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c20
	jmp .L_lambda_simple_end_3c20
.L_lambda_simple_code_3c20:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c20
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c20:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c21:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c21
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c21
.L_lambda_simple_env_end_3c21:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c21:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c21
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c21
.L_lambda_simple_params_end_3c21:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c21
	jmp .L_lambda_simple_end_3c21
.L_lambda_simple_code_3c21:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 4
	je .L_lambda_simple_arity_check_ok_3c21
	push qword [rsp + 8 * 2]
	push 4
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c21:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0410
	; preparing a non tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ac
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var char=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ad
	; preparing a tail-call
	mov rax, PARAM(3)	; param len
	push rax
	mov rax, PARAM(2)	; param str2
	push rax
	mov rax, PARAM(1)	; param str1
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 4 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eab:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eab
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eab
.L_tc_recycle_frame_done_4eab:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52ad
.L_if_else_52ad:
	mov rax, L_constants + 2
.L_if_end_52ad:
	jmp .L_if_end_52ac
.L_if_else_52ac:
	mov rax, L_constants + 2
.L_if_end_52ac:
.L_or_end_0410:
	leave
	ret AND_KILL_FRAME(4)
.L_lambda_simple_end_3c21:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c22:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c22
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c22
.L_lambda_simple_env_end_3c22:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c22:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c22
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c22
.L_lambda_simple_params_end_3c22:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c22
	jmp .L_lambda_simple_end_3c22
.L_lambda_simple_code_3c22:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c22
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c22:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param str2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c23:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c23
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c23
.L_lambda_simple_env_end_3c23:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c23:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c23
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c23
.L_lambda_simple_params_end_3c23:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c23
	jmp .L_lambda_simple_end_3c23
.L_lambda_simple_code_3c23:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c23
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c23:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param len2
	push rax
	mov rax, PARAM(0)	; param len1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ae
	; preparing a tail-call
	mov rax, PARAM(0)	; param len1
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var str2
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str1
	push rax
	mov rax, L_constants + 2023
	push rax
	push 4	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 4 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eac:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eac
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eac
.L_tc_recycle_frame_done_4eac:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52ae
.L_if_else_52ae:
	mov rax, L_constants + 2
.L_if_end_52ae:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c23:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ead:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ead
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ead
.L_tc_recycle_frame_done_4ead:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c22:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c24:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c24
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c24
.L_lambda_simple_env_end_3c24:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c24:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c24
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c24
.L_lambda_simple_params_end_3c24:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c24
	jmp .L_lambda_simple_end_3c24
.L_lambda_simple_code_3c24:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c24
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c24:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c25:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c25
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c25
.L_lambda_simple_env_end_3c25:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c25:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c25
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c25
.L_lambda_simple_params_end_3c25:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c25
	jmp .L_lambda_simple_end_3c25
.L_lambda_simple_code_3c25:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c25
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c25:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c26:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_simple_env_end_3c26
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c26
.L_lambda_simple_env_end_3c26:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c26:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c26
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c26
.L_lambda_simple_params_end_3c26:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c26
	jmp .L_lambda_simple_end_3c26
.L_lambda_simple_code_3c26:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c26
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c26:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0411
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var binary-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52af
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eae:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eae
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eae
.L_tc_recycle_frame_done_4eae:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52af
.L_if_else_52af:
	mov rax, L_constants + 2
.L_if_end_52af:
.L_or_end_0411:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c26:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 5	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08cf:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 4
	je .L_lambda_opt_env_end_08cf
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08cf
.L_lambda_opt_env_end_08cf:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08cf:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08cf
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08cf
.L_lambda_opt_params_end_08cf:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08cf
	jmp .L_lambda_opt_end_08cf
.L_lambda_opt_code_08cf:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08cf
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08cf
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08cf:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c09
.L_lambda_opt_stack_shrink_loop_2c08:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c08
.L_lambda_opt_stack_shrink_loop_2c09:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c0a:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c0a
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08cf
.L_lambda_opt_stack_shrink_loop_2c0b:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c0b
jmp .L_lambda_opt_stack_adjusted_08cf
.L_lambda_opt_arity_check_exact_08cf:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c07:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08cf
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c07
.L_lambda_opt_stack_shrink_loop_exit_08cf:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08cf:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(1)	; param strs
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eaf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eaf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eaf
.L_tc_recycle_frame_done_4eaf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08cf:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c25:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb0
.L_tc_recycle_frame_done_4eb0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c24:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb1
.L_tc_recycle_frame_done_4eb1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c20:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb2
.L_tc_recycle_frame_done_4eb2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c1f:	; new closure is in rax
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c27:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c27
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c27
.L_lambda_simple_env_end_3c27:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c27:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c27
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c27
.L_lambda_simple_params_end_3c27:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c27
	jmp .L_lambda_simple_end_3c27
.L_lambda_simple_code_3c27:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c27
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c27:
	enter 0, 0
	; preparing a non tail-call
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_146], rax
	mov rax, sob_void

	; preparing a non tail-call
	mov rax, qword [free_var_137]	; free var char-ci=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param make-string=?
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_151], rax
	mov rax, sob_void
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c27:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c28:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c28
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c28
.L_lambda_simple_env_end_3c28:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c28:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c28
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c28
.L_lambda_simple_params_end_3c28:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c28
	jmp .L_lambda_simple_end_3c28
.L_lambda_simple_code_3c28:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c28
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c28:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b0
	mov rax, L_constants + 2023
	jmp .L_if_end_52b0
.L_if_else_52b0:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_154]	; free var length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2158
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb3
.L_tc_recycle_frame_done_4eb3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52b0:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c28:	; new closure is in rax
	mov qword [free_var_154], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c29:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c29
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c29
.L_lambda_simple_env_end_3c29:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c29:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c29
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c29
.L_lambda_simple_params_end_3c29:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c29
	jmp .L_lambda_simple_end_3c29
.L_lambda_simple_code_3c29:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c29
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c29:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	jne .L_or_end_0412
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b1
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_102]	; free var list?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb4
.L_tc_recycle_frame_done_4eb4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b1
.L_if_else_52b1:
	mov rax, L_constants + 2
.L_if_end_52b1:
.L_or_end_0412:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c29:	; new closure is in rax
	mov qword [free_var_102], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c2a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2a
.L_lambda_simple_env_end_3c2a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2a:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c2a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2a
.L_lambda_simple_params_end_3c2a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2a
	jmp .L_lambda_simple_end_3c2a
.L_lambda_simple_code_3c2a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c2a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2a:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08d0:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08d0
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08d0
.L_lambda_opt_env_end_08d0:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08d0:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08d0
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08d0
.L_lambda_opt_params_end_08d0:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08d0
	jmp .L_lambda_opt_end_08d0
.L_lambda_opt_code_08d0:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08d0
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08d0
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08d0:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c0e
.L_lambda_opt_stack_shrink_loop_2c0d:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c0d
.L_lambda_opt_stack_shrink_loop_2c0e:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c0f:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c0f
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08d0
.L_lambda_opt_stack_shrink_loop_2c10:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c10
jmp .L_lambda_opt_stack_adjusted_08d0
.L_lambda_opt_arity_check_exact_08d0:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c0c:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08d0
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c0c
.L_lambda_opt_stack_shrink_loop_exit_08d0:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08d0:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b2
	mov rax, L_constants + 0
	jmp .L_if_end_52b2
.L_if_else_52b2:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b4
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b4
.L_if_else_52b4:
	mov rax, L_constants + 2
.L_if_end_52b4:
	cmp rax, sob_boolean_false
	je .L_if_else_52b3
	; preparing a non tail-call
	mov rax, PARAM(1)	; param xs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b3
.L_if_else_52b3:
	; preparing a non tail-call
	mov rax, L_constants + 2939
	push rax
	mov rax, L_constants + 2930
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_52b3:
.L_if_end_52b2:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c2b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2b
.L_lambda_simple_env_end_3c2b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2b:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c2b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2b
.L_lambda_simple_params_end_3c2b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2b
	jmp .L_lambda_simple_end_3c2b
.L_lambda_simple_code_3c2b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c2b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2b:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-vector
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb5
.L_tc_recycle_frame_done_4eb5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c2b:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb6
.L_tc_recycle_frame_done_4eb6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08d0:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c2a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_57], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c2c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2c
.L_lambda_simple_env_end_3c2c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c2c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2c
.L_lambda_simple_params_end_3c2c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2c
	jmp .L_lambda_simple_end_3c2c
.L_lambda_simple_code_3c2c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c2c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2c:
	enter 0, 0
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08d1:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08d1
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08d1
.L_lambda_opt_env_end_08d1:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08d1:	; copy params
	cmp rsi, 1
	je .L_lambda_opt_params_end_08d1
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08d1
.L_lambda_opt_params_end_08d1:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08d1
	jmp .L_lambda_opt_end_08d1
.L_lambda_opt_code_08d1:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_opt_arity_check_exact_08d1
	cmp qword [rsp + 8 * 2], 1
	jg .L_lambda_opt_arity_check_more_08d1
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08d1:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 1
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c13
.L_lambda_opt_stack_shrink_loop_2c12:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c12
.L_lambda_opt_stack_shrink_loop_2c13:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 1
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c14:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c14
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08d1
.L_lambda_opt_stack_shrink_loop_2c15:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c15
jmp .L_lambda_opt_stack_adjusted_08d1
.L_lambda_opt_arity_check_exact_08d1:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 1]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c11:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08d1
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c11
.L_lambda_opt_stack_shrink_loop_exit_08d1:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08d1:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b5
	mov rax, L_constants + 4
	jmp .L_if_end_52b5
.L_if_else_52b5:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b7
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b7
.L_if_else_52b7:
	mov rax, L_constants + 2
.L_if_end_52b7:
	cmp rax, sob_boolean_false
	je .L_if_else_52b6
	; preparing a non tail-call
	mov rax, PARAM(1)	; param chs
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b6
.L_if_else_52b6:
	; preparing a non tail-call
	mov rax, L_constants + 3000
	push rax
	mov rax, L_constants + 2991
	push rax
	push 2	; arg count
	mov rax, qword [free_var_42]	; free var error
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
.L_if_end_52b6:
.L_if_end_52b5:
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c2d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2d
.L_lambda_simple_env_end_3c2d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2d:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c2d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2d
.L_lambda_simple_params_end_3c2d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2d
	jmp .L_lambda_simple_end_3c2d
.L_lambda_simple_code_3c2d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c2d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2d:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var asm-make-string
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb7
.L_tc_recycle_frame_done_4eb7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c2d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb8
.L_tc_recycle_frame_done_4eb8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_opt_end_08d1:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c2c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_58], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c2e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2e
.L_lambda_simple_env_end_3c2e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c2e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2e
.L_lambda_simple_params_end_3c2e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2e
	jmp .L_lambda_simple_end_3c2e
.L_lambda_simple_code_3c2e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c2e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2e:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c2f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c2f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c2f
.L_lambda_simple_env_end_3c2f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c2f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c2f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c2f
.L_lambda_simple_params_end_3c2f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c2f
	jmp .L_lambda_simple_end_3c2f
.L_lambda_simple_code_3c2f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c2f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c2f:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b8
	; preparing a tail-call
	mov rax, L_constants + 0
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eb9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eb9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eb9
.L_tc_recycle_frame_done_4eb9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b8
.L_if_else_52b8:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c30:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c30
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c30
.L_lambda_simple_env_end_3c30:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c30:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c30
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c30
.L_lambda_simple_params_end_3c30:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c30
	jmp .L_lambda_simple_end_3c30
.L_lambda_simple_code_3c30:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c30
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c30:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param v
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c30:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eba:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eba
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eba
.L_tc_recycle_frame_done_4eba:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52b8:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c2f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c31:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c31
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c31
.L_lambda_simple_env_end_3c31:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c31:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c31
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c31
.L_lambda_simple_params_end_3c31:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c31
	jmp .L_lambda_simple_end_3c31
.L_lambda_simple_code_3c31:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c31
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c31:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ebb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ebb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ebb
.L_tc_recycle_frame_done_4ebb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c31:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c2e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_155], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c32:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c32
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c32
.L_lambda_simple_env_end_3c32:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c32:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c32
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c32
.L_lambda_simple_params_end_3c32:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c32
	jmp .L_lambda_simple_end_3c32
.L_lambda_simple_code_3c32:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c32
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c32:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c33:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c33
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c33
.L_lambda_simple_env_end_3c33:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c33:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c33
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c33
.L_lambda_simple_params_end_3c33:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c33
	jmp .L_lambda_simple_end_3c33
.L_lambda_simple_code_3c33:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c33
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c33:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52b9
	; preparing a tail-call
	mov rax, L_constants + 4
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ebc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ebc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ebc
.L_tc_recycle_frame_done_4ebc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52b9
.L_if_else_52b9:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c34:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c34
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c34
.L_lambda_simple_env_end_3c34:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c34:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c34
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c34
.L_lambda_simple_params_end_3c34:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c34
	jmp .L_lambda_simple_end_3c34
.L_lambda_simple_code_3c34:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c34
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c34:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	mov rax, PARAM(0)	; param str
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c34:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ebd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ebd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ebd
.L_tc_recycle_frame_done_4ebd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52b9:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c33:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c35:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c35
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c35
.L_lambda_simple_env_end_3c35:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c35:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c35
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c35
.L_lambda_simple_params_end_3c35:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c35
	jmp .L_lambda_simple_end_3c35
.L_lambda_simple_code_3c35:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c35
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c35:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param s
	push rax
	push 2	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ebe:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ebe
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ebe
.L_tc_recycle_frame_done_4ebe:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c35:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c32:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_142], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08d2:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_opt_env_end_08d2
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08d2
.L_lambda_opt_env_end_08d2:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08d2:	; copy params
	cmp rsi, 0
	je .L_lambda_opt_params_end_08d2
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08d2
.L_lambda_opt_params_end_08d2:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08d2
	jmp .L_lambda_opt_end_08d2
.L_lambda_opt_code_08d2:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08d2
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08d2
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08d2:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c18
.L_lambda_opt_stack_shrink_loop_2c17:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c17
.L_lambda_opt_stack_shrink_loop_2c18:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c19:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c19
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08d2
.L_lambda_opt_stack_shrink_loop_2c1a:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c1a
jmp .L_lambda_opt_stack_adjusted_08d2
.L_lambda_opt_arity_check_exact_08d2:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c16:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08d2
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c16
.L_lambda_opt_stack_shrink_loop_exit_08d2:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08d2:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_155]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ebf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ebf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ebf
.L_tc_recycle_frame_done_4ebf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08d2:	; new closure is in rax
	mov qword [free_var_156], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c36:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c36
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c36
.L_lambda_simple_env_end_3c36:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c36:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c36
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c36
.L_lambda_simple_params_end_3c36:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c36
	jmp .L_lambda_simple_end_3c36
.L_lambda_simple_code_3c36:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c36
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c36:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c37:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c37
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c37
.L_lambda_simple_env_end_3c37:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c37:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c37
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c37
.L_lambda_simple_params_end_3c37:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c37
	jmp .L_lambda_simple_end_3c37
.L_lambda_simple_code_3c37:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c37
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c37:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ba
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec0
.L_tc_recycle_frame_done_4ec0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52ba
.L_if_else_52ba:
	mov rax, L_constants + 1
.L_if_end_52ba:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c37:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c38:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c38
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c38
.L_lambda_simple_env_end_3c38:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c38:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c38
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c38
.L_lambda_simple_params_end_3c38:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c38
	jmp .L_lambda_simple_end_3c38
.L_lambda_simple_code_3c38:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c38
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c38:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec1
.L_tc_recycle_frame_done_4ec1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c38:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c36:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_143], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c39:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c39
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c39
.L_lambda_simple_env_end_3c39:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c39:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c39
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c39
.L_lambda_simple_params_end_3c39:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c39
	jmp .L_lambda_simple_end_3c39
.L_lambda_simple_code_3c39:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c39
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c39:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c3a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3a
.L_lambda_simple_env_end_3c3a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c3a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3a
.L_lambda_simple_params_end_3c3a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3a
	jmp .L_lambda_simple_end_3c3a
.L_lambda_simple_code_3c3a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c3a
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3a:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52bb
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec2
.L_tc_recycle_frame_done_4ec2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52bb
.L_if_else_52bb:
	mov rax, L_constants + 1
.L_if_end_52bb:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c3a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c3b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3b
.L_lambda_simple_env_end_3c3b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3b:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c3b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3b
.L_lambda_simple_params_end_3c3b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3b
	jmp .L_lambda_simple_end_3c3b
.L_lambda_simple_code_3c3b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c3b
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param v
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param v
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec3
.L_tc_recycle_frame_done_4ec3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c3b:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c39:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_157], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c3c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3c
.L_lambda_simple_env_end_3c3c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c3c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3c
.L_lambda_simple_params_end_3c3c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3c
	jmp .L_lambda_simple_end_3c3c
.L_lambda_simple_code_3c3c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c3c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3c:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param n
	push rax
	; preparing a non tail-call
	push 0	; arg count
	mov rax, qword [free_var_26]	; free var trng
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec4
.L_tc_recycle_frame_done_4ec4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c3c:	; new closure is in rax
	mov qword [free_var_158], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c3d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3d
.L_lambda_simple_env_end_3c3d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c3d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3d
.L_lambda_simple_params_end_3c3d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3d
	jmp .L_lambda_simple_end_3c3d
.L_lambda_simple_code_3c3d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c3d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3d:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	mov rax, L_constants + 2023
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec5
.L_tc_recycle_frame_done_4ec5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c3d:	; new closure is in rax
	mov qword [free_var_159], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c3e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3e
.L_lambda_simple_env_end_3c3e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c3e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3e
.L_lambda_simple_params_end_3c3e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3e
	jmp .L_lambda_simple_end_3c3e
.L_lambda_simple_code_3c3e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c3e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3e:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	mov rax, PARAM(0)	; param x
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec6
.L_tc_recycle_frame_done_4ec6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c3e:	; new closure is in rax
	mov qword [free_var_160], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c3f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c3f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c3f
.L_lambda_simple_env_end_3c3f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c3f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c3f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c3f
.L_lambda_simple_params_end_3c3f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c3f
	jmp .L_lambda_simple_end_3c3f
.L_lambda_simple_code_3c3f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c3f
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c3f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 3174
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_50]	; free var remainder
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec7
.L_tc_recycle_frame_done_4ec7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c3f:	; new closure is in rax
	mov qword [free_var_161], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c40:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c40
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c40
.L_lambda_simple_env_end_3c40:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c40:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c40
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c40
.L_lambda_simple_params_end_3c40:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c40
	jmp .L_lambda_simple_end_3c40
.L_lambda_simple_code_3c40:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c40
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c40:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_161]	; free var even?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_104]	; free var not
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec8
.L_tc_recycle_frame_done_4ec8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c40:	; new closure is in rax
	mov qword [free_var_162], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c41:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c41
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c41
.L_lambda_simple_env_end_3c41:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c41:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c41
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c41
.L_lambda_simple_params_end_3c41:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c41
	jmp .L_lambda_simple_end_3c41
.L_lambda_simple_code_3c41:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c41
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c41:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_160]	; free var negative?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52bc
	; preparing a tail-call
	mov rax, PARAM(0)	; param x
	push rax
	push 1	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ec9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ec9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ec9
.L_tc_recycle_frame_done_4ec9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52bc
.L_if_else_52bc:
	mov rax, PARAM(0)	; param x
.L_if_end_52bc:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c41:	; new closure is in rax
	mov qword [free_var_163], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c42:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c42
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c42
.L_lambda_simple_env_end_3c42:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c42:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c42
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c42
.L_lambda_simple_params_end_3c42:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c42
	jmp .L_lambda_simple_end_3c42
.L_lambda_simple_code_3c42:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c42
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c42:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52be
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_1]	; free var pair?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52be
.L_if_else_52be:
	mov rax, L_constants + 2
.L_if_end_52be:
	cmp rax, sob_boolean_false
	je .L_if_else_52bd
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52bf
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eca:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eca
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eca
.L_tc_recycle_frame_done_4eca:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52bf
.L_if_else_52bf:
	mov rax, L_constants + 2
.L_if_end_52bf:
	jmp .L_if_end_52bd
.L_if_else_52bd:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c1
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_6]	; free var vector?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c2
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c2
.L_if_else_52c2:
	mov rax, L_constants + 2
.L_if_end_52c2:
	jmp .L_if_end_52c1
.L_if_else_52c1:
	mov rax, L_constants + 2
.L_if_end_52c1:
	cmp rax, sob_boolean_false
	je .L_if_else_52c0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_164]	; free var equal?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ecb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ecb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ecb
.L_tc_recycle_frame_done_4ecb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c0
.L_if_else_52c0:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_4]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c4
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_4]	; free var string?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c5
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c5
.L_if_else_52c5:
	mov rax, L_constants + 2
.L_if_end_52c5:
	jmp .L_if_end_52c4
.L_if_else_52c4:
	mov rax, L_constants + 2
.L_if_end_52c4:
	cmp rax, sob_boolean_false
	je .L_if_else_52c3
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_146]	; free var string=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ecc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ecc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ecc
.L_tc_recycle_frame_done_4ecc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c3
.L_if_else_52c3:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_11]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c7
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_11]	; free var number?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c7
.L_if_else_52c7:
	mov rax, L_constants + 2
.L_if_end_52c7:
	cmp rax, sob_boolean_false
	je .L_if_else_52c6
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ecd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ecd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ecd
.L_tc_recycle_frame_done_4ecd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c6
.L_if_else_52c6:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param e1
	push rax
	push 1	; arg count
	mov rax, qword [free_var_3]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52c9
	; preparing a non tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	push 1	; arg count
	mov rax, qword [free_var_3]	; free var char?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c9
.L_if_else_52c9:
	mov rax, L_constants + 2
.L_if_end_52c9:
	cmp rax, sob_boolean_false
	je .L_if_else_52c8
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_130]	; free var char=?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ece:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ece
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ece
.L_tc_recycle_frame_done_4ece:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52c8
.L_if_else_52c8:
	; preparing a tail-call
	mov rax, PARAM(1)	; param e2
	push rax
	mov rax, PARAM(0)	; param e1
	push rax
	push 2	; arg count
	mov rax, qword [free_var_61]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ecf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ecf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ecf
.L_tc_recycle_frame_done_4ecf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52c8:
.L_if_end_52c6:
.L_if_end_52c3:
.L_if_end_52c0:
.L_if_end_52bd:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c42:	; new closure is in rax
	mov qword [free_var_164], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c43:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c43
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c43
.L_lambda_simple_env_end_3c43:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c43:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c43
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c43
.L_lambda_simple_params_end_3c43:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c43
	jmp .L_lambda_simple_end_3c43
.L_lambda_simple_code_3c43:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c43
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c43:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ca
	mov rax, L_constants + 2
	jmp .L_if_end_52ca
.L_if_else_52ca:
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_74]	; free var caar
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_61]	; free var eq?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52cb
	; preparing a tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed0
.L_tc_recycle_frame_done_4ed0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52cb
.L_if_else_52cb:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_165]	; free var assoc
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed1
.L_tc_recycle_frame_done_4ed1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52cb:
.L_if_end_52ca:
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c43:	; new closure is in rax
	mov qword [free_var_165], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c44:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c44
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c44
.L_lambda_simple_env_end_3c44:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c44:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c44
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c44
.L_lambda_simple_params_end_3c44:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c44
	jmp .L_lambda_simple_end_3c44
.L_lambda_simple_code_3c44:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c44
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c44:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(1)
	mov [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c45:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c45
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c45
.L_lambda_simple_env_end_3c45:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c45:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c45
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c45
.L_lambda_simple_params_end_3c45:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c45
	jmp .L_lambda_simple_end_3c45
.L_lambda_simple_code_3c45:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c45
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c45:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52cc
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_52cc
.L_if_else_52cc:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c46:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c46
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c46
.L_lambda_simple_env_end_3c46:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c46:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_3c46
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c46
.L_lambda_simple_params_end_3c46:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c46
	jmp .L_lambda_simple_end_3c46
.L_lambda_simple_code_3c46:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c46
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c46:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed2
.L_tc_recycle_frame_done_4ed2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c46:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed3
.L_tc_recycle_frame_done_4ed3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52cc:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c45:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c47:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c47
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c47
.L_lambda_simple_env_end_3c47:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c47:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c47
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c47
.L_lambda_simple_params_end_3c47:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c47
	jmp .L_lambda_simple_end_3c47
.L_lambda_simple_code_3c47:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_3c47
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c47:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52cd
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param str
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed4
.L_tc_recycle_frame_done_4ed4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52cd
.L_if_else_52cd:
	mov rax, PARAM(1)	; param i
.L_if_end_52cd:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_3c47:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08d3:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08d3
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08d3
.L_lambda_opt_env_end_08d3:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08d3:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_08d3
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08d3
.L_lambda_opt_params_end_08d3:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08d3
	jmp .L_lambda_opt_end_08d3
.L_lambda_opt_code_08d3:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08d3
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08d3
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08d3:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c1d
.L_lambda_opt_stack_shrink_loop_2c1c:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c1c
.L_lambda_opt_stack_shrink_loop_2c1d:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c1e:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c1e
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08d3
.L_lambda_opt_stack_shrink_loop_2c1f:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c1f
jmp .L_lambda_opt_stack_adjusted_08d3
.L_lambda_opt_arity_check_exact_08d3:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c1b:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08d3
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c1b
.L_lambda_opt_stack_shrink_loop_exit_08d3:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08d3:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, L_constants + 2023
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param strings
	push rax
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed5
.L_tc_recycle_frame_done_4ed5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08d3:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c44:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_166], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	mov rax, L_constants + 1881
	push rax
	push 2	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c48:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c48
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c48
.L_lambda_simple_env_end_3c48:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c48:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c48
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c48
.L_lambda_simple_params_end_3c48:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c48
	jmp .L_lambda_simple_end_3c48
.L_lambda_simple_code_3c48:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c48
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c48:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(1)
	mov [rax], rbx
	mov PARAM(1), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c49:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c49
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c49
.L_lambda_simple_env_end_3c49:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c49:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c49
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c49
.L_lambda_simple_params_end_3c49:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c49
	jmp .L_lambda_simple_end_3c49
.L_lambda_simple_code_3c49:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c49
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c49:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_0]	; free var null?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52ce
	mov rax, PARAM(0)	; param target
	jmp .L_if_end_52ce
.L_if_else_52ce:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	; preparing a non tail-call
	mov rax, PARAM(2)	; param s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_16]	; free var car
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c4a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4a
.L_lambda_simple_env_end_3c4a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4a:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_3c4a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4a
.L_lambda_simple_params_end_3c4a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4a
	jmp .L_lambda_simple_end_3c4a
.L_lambda_simple_code_3c4a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c4a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4a:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var s
	push rax
	push 1	; arg count
	mov rax, qword [free_var_17]	; free var cdr
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var target
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed6
.L_tc_recycle_frame_done_4ed6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c4a:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed7
.L_tc_recycle_frame_done_4ed7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52ce:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c49:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c4b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4b
.L_lambda_simple_env_end_3c4b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4b:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c4b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4b
.L_lambda_simple_params_end_3c4b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4b
	jmp .L_lambda_simple_end_3c4b
.L_lambda_simple_code_3c4b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 5
	je .L_lambda_simple_arity_check_ok_3c4b
	push qword [rsp + 8 * 2]
	push 5
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4b:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52cf
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(3)	; param j
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	mov rax, PARAM(4)	; param limit
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(3)	; param j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(2)	; param vec
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param target
	push rax
	push 5	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var add
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 5 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed8
.L_tc_recycle_frame_done_4ed8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52cf
.L_if_else_52cf:
	mov rax, PARAM(1)	; param i
.L_if_end_52cf:
	leave
	ret AND_KILL_FRAME(5)
.L_lambda_simple_end_3c4b:	; new closure is in rax
	push rax
	mov rax, PARAM(1)	; param add
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_opt_env_loop_08d4:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_opt_env_end_08d4
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_opt_env_loop_08d4
.L_lambda_opt_env_end_08d4:
	pop rbx
	mov rsi, 0
.L_lambda_opt_params_loop_08d4:	; copy params
	cmp rsi, 2
	je .L_lambda_opt_params_end_08d4
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_opt_params_loop_08d4
.L_lambda_opt_params_end_08d4:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_opt_code_08d4
	jmp .L_lambda_opt_end_08d4
.L_lambda_opt_code_08d4:	; lambda-opt body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_opt_arity_check_exact_08d4
	cmp qword [rsp + 8 * 2], 0
	jg .L_lambda_opt_arity_check_more_08d4
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_opt
.L_lambda_opt_arity_check_more_08d4:
	mov r8, qword [rsp + 8 * 2]
	mov r9 , 0
	mov r15, rsp
	sub r8, r9
	mov r9, 0
	lea rbx, [r15 + 8 * 2]
	mov rax, qword [r15 + 8 * 2]
	imul rax, 8
	add rbx, rax
	mov rdx , qword [rbx]
	mov r10 , rbx
	mov rdi, (1 + 8 + 8)	; sob pair
	push rdx
	push rbx
	push r8
	push r9
	push r10
	push r15
	call malloc
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rdx
	mov byte qword [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov SOB_PAIR_CDR(rax), sob_nil
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	je .L_lambda_opt_stack_shrink_loop_2c22
.L_lambda_opt_stack_shrink_loop_2c21:
	mov rdx, qword [rbx]
	push rbx
	push r8
	push r9
	push r10
	push r15
	push rdx
	mov rdi, (1 + 8 + 8)
	call malloc
	pop rdx
	pop r15
	pop r10
	pop r9
	pop r8
	pop rbx
	mov byte [rax], T_pair
	mov SOB_PAIR_CAR(rax), rdx
	mov r14, qword [r10]
	mov SOB_PAIR_CDR(rax), r14
	mov qword [r10], rax
	inc r9
	sub rbx, 8
	cmp r9, r8
	jl .L_lambda_opt_stack_shrink_loop_2c21
.L_lambda_opt_stack_shrink_loop_2c22:
	lea rdx, [r15 + 8 * 2]
	mov qword [rdx], 0
	add qword [rdx] , 1
	mov r9, r8
	dec r9
	lea r9, [rbx + 8 * r9]
.L_lambda_opt_stack_shrink_loop_2c23:
	mov rax, qword [rbx]
	mov qword [r9], rax
	sub r9 , 8
	sub rbx, 8
	cmp rbx, r15
	jne .L_lambda_opt_stack_shrink_loop_2c23
	mov rax, qword [rbx]
	mov qword [r9], rax
	mov r9, r8
	sub r9 , 1
	cmp r9, 0
je .L_lambda_opt_stack_adjusted_08d4
.L_lambda_opt_stack_shrink_loop_2c24:
	pop rax
	dec r9
	cmp r9, 0
	jg .L_lambda_opt_stack_shrink_loop_2c24
jmp .L_lambda_opt_stack_adjusted_08d4
.L_lambda_opt_arity_check_exact_08d4:
	mov r15, rsp
	lea rbx, [r15 + 8 * 2 + 8 * 0]
	mov rcx, qword [rbx]
	mov qword [rbx], sob_nil
	sub rbx, 8
.L_lambda_opt_stack_shrink_loop_2c20:
	mov rdx, qword [rbx]
	mov qword [rbx], rcx
	cmp rbx, r15
je .L_lambda_opt_stack_shrink_loop_exit_08d4
	mov rcx, rdx
	sub rbx, 8
	jmp .L_lambda_opt_stack_shrink_loop_2c20
.L_lambda_opt_stack_shrink_loop_exit_08d4:
	push rdx
	mov r15, rsp
	add r15, 16
	mov rbx, qword [r15]
	inc rbx
	mov qword [r15], rbx
.L_lambda_opt_stack_adjusted_08d4:
	enter 0, 0
	; preparing a tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, L_constants + 2023
	push rax
	; preparing a non tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param vectors
	push rax
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_109]	; free var map
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	push rax
	push 2	; arg count
	mov rax, qword [free_var_107]	; free var apply
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ed9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ed9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ed9
.L_tc_recycle_frame_done_4ed9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_opt_end_08d4:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c48:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_167], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c4c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4c
.L_lambda_simple_env_end_3c4c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4c:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c4c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4c
.L_lambda_simple_params_end_3c4c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4c
	jmp .L_lambda_simple_end_3c4c
.L_lambda_simple_code_3c4c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c4c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4c:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_143]	; free var string->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_142]	; free var list->string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eda:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eda
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eda
.L_tc_recycle_frame_done_4eda:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c4c:	; new closure is in rax
	mov qword [free_var_168], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c4d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4d
.L_lambda_simple_env_end_3c4d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4d:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c4d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4d
.L_lambda_simple_params_end_3c4d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4d
	jmp .L_lambda_simple_end_3c4d
.L_lambda_simple_code_3c4d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c4d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4d:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_157]	; free var vector->list
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_111]	; free var reverse
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, qword [free_var_155]	; free var list->vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4edb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4edb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4edb
.L_tc_recycle_frame_done_4edb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c4d:	; new closure is in rax
	mov qword [free_var_169], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c4e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4e
.L_lambda_simple_env_end_3c4e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4e:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c4e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4e
.L_lambda_simple_params_end_3c4e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4e
	jmp .L_lambda_simple_end_3c4e
.L_lambda_simple_code_3c4e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c4e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4e:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c4f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c4f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c4f
.L_lambda_simple_env_end_3c4f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c4f:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c4f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c4f
.L_lambda_simple_params_end_3c4f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c4f
	jmp .L_lambda_simple_end_3c4f
.L_lambda_simple_code_3c4f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c4f
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c4f:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c50:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c50
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c50
.L_lambda_simple_env_end_3c50:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c50:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_3c50
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c50
.L_lambda_simple_params_end_3c50:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c50
	jmp .L_lambda_simple_end_3c50
.L_lambda_simple_code_3c50:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c50
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c50:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 2	; arg count
	mov rax, qword [free_var_53]	; free var string-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4edc:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4edc
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4edc
.L_tc_recycle_frame_done_4edc:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c50:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4edd:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4edd
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4edd
.L_tc_recycle_frame_done_4edd:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d0
.L_if_else_52d0:
	mov rax, PARAM(0)	; param str
.L_if_end_52d0:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c4f:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c51:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c51
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c51
.L_lambda_simple_env_end_3c51:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c51:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c51
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c51
.L_lambda_simple_params_end_3c51:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c51
	jmp .L_lambda_simple_end_3c51
.L_lambda_simple_code_3c51:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c51
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c51:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param str
	push rax
	push 1	; arg count
	mov rax, qword [free_var_18]	; free var string-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c52:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c52
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c52
.L_lambda_simple_env_end_3c52:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c52:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c52
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c52
.L_lambda_simple_params_end_3c52:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c52
	jmp .L_lambda_simple_end_3c52
.L_lambda_simple_code_3c52:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c52
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c52:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d1
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	jmp .L_if_end_52d1
.L_if_else_52d1:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ede:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ede
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ede
.L_tc_recycle_frame_done_4ede:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52d1:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c52:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4edf:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4edf
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4edf
.L_tc_recycle_frame_done_4edf:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c51:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c4e:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_170], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	; preparing a non tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c53:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c53
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c53
.L_lambda_simple_env_end_3c53:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c53:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c53
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c53
.L_lambda_simple_params_end_3c53:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c53
	jmp .L_lambda_simple_end_3c53
.L_lambda_simple_code_3c53:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c53
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c53:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c54:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c54
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c54
.L_lambda_simple_env_end_3c54:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c54:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c54
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c54
.L_lambda_simple_params_end_3c54:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c54
	jmp .L_lambda_simple_end_3c54
.L_lambda_simple_code_3c54:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c54
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c54:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param j
	push rax
	mov rax, PARAM(1)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d2
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(1)	; param i
	push rax
	mov rax, PARAM(0)	; param vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 3	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c55:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c55
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c55
.L_lambda_simple_env_end_3c55:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c55:	; copy params
	cmp rsi, 3
	je .L_lambda_simple_params_end_3c55
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c55
.L_lambda_simple_params_end_3c55:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c55
	jmp .L_lambda_simple_end_3c55
.L_lambda_simple_code_3c55:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c55
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c55:
	enter 0, 0
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 2	; arg count
	mov rax, qword [free_var_54]	; free var vector-ref
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a non tail-call
	mov rax, PARAM(0)	; param ch
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 2]	; bound var j
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 1]	; bound var i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee0
.L_tc_recycle_frame_done_4ee0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c55:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee1
.L_tc_recycle_frame_done_4ee1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d2
.L_if_else_52d2:
	mov rax, PARAM(0)	; param vec
.L_if_end_52d2:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c54:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c56:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c56
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c56
.L_lambda_simple_env_end_3c56:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c56:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c56
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c56
.L_lambda_simple_params_end_3c56:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c56
	jmp .L_lambda_simple_end_3c56
.L_lambda_simple_code_3c56:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c56
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c56:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param vec
	push rax
	push 1	; arg count
	mov rax, qword [free_var_19]	; free var vector-length
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c57:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c57
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c57
.L_lambda_simple_env_end_3c57:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c57:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c57
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c57
.L_lambda_simple_params_end_3c57:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c57
	jmp .L_lambda_simple_end_3c57
.L_lambda_simple_code_3c57:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c57
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c57:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d3
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	jmp .L_if_end_52d3
.L_if_else_52d3:
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 2023
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 3 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee2:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee2
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee2
.L_tc_recycle_frame_done_4ee2:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52d3:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c57:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee3:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee3
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee3
.L_tc_recycle_frame_done_4ee3:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c56:	; new closure is in rax
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c53:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	mov qword [free_var_171], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c58:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c58
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c58
.L_lambda_simple_env_end_3c58:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c58:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c58
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c58
.L_lambda_simple_params_end_3c58:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c58
	jmp .L_lambda_simple_end_3c58
.L_lambda_simple_code_3c58:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c58
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c58:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c59:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c59
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c59
.L_lambda_simple_env_end_3c59:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c59:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c59
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c59
.L_lambda_simple_params_end_3c59:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c59
	jmp .L_lambda_simple_end_3c59
.L_lambda_simple_code_3c59:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c59
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c59:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5a:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c5a
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5a
.L_lambda_simple_env_end_3c5a:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5a:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c5a
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5a
.L_lambda_simple_params_end_3c5a:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5a
	jmp .L_lambda_simple_end_3c5a
.L_lambda_simple_code_3c5a:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c5a
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5a:
	enter 0, 0
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d4
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 2	; arg count
	mov rax, qword [free_var_13]	; free var cons
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee4:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee4
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee4
.L_tc_recycle_frame_done_4ee4:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d4
.L_if_else_52d4:
	mov rax, L_constants + 1
.L_if_end_52d4:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c5a:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee5:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee5
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee5
.L_tc_recycle_frame_done_4ee5:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c59:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee6:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee6
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee6
.L_tc_recycle_frame_done_4ee6:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c58:	; new closure is in rax
	mov qword [free_var_172], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5b:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c5b
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5b
.L_lambda_simple_env_end_3c5b:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5b:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c5b
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5b
.L_lambda_simple_params_end_3c5b:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5b
	jmp .L_lambda_simple_end_3c5b
.L_lambda_simple_code_3c5b:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c5b
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5b:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_58]	; free var make-string
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5c:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c5c
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5c
.L_lambda_simple_env_end_3c5c:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5c:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c5c
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5c
.L_lambda_simple_params_end_3c5c:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5c
	jmp .L_lambda_simple_end_3c5c
.L_lambda_simple_code_3c5c:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c5c
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5c:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5d:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c5d
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5d
.L_lambda_simple_env_end_3c5d:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5d:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c5d
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5d
.L_lambda_simple_params_end_3c5d:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5d
	jmp .L_lambda_simple_end_3c5d
.L_lambda_simple_code_3c5d:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c5d
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5d:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5e:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c5e
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5e
.L_lambda_simple_env_end_3c5e:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5e:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c5e
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5e
.L_lambda_simple_params_end_3c5e:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5e
	jmp .L_lambda_simple_end_3c5e
.L_lambda_simple_code_3c5e:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c5e
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5e:
	enter 0, 0
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d5
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
	push rax
	push 3	; arg count
	mov rax, qword [free_var_56]	; free var string-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee7:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee7
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee7
.L_tc_recycle_frame_done_4ee7:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d5
.L_if_else_52d5:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var str
.L_if_end_52d5:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c5e:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee8:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee8
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee8
.L_tc_recycle_frame_done_4ee8:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c5d:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ee9:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ee9
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ee9
.L_tc_recycle_frame_done_4ee9:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c5c:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eea:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eea
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eea
.L_tc_recycle_frame_done_4eea:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c5b:	; new closure is in rax
	mov qword [free_var_173], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c5f:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c5f
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c5f
.L_lambda_simple_env_end_3c5f:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c5f:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c5f
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c5f
.L_lambda_simple_params_end_3c5f:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c5f
	jmp .L_lambda_simple_end_3c5f
.L_lambda_simple_code_3c5f:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 2
	je .L_lambda_simple_arity_check_ok_3c5f
	push qword [rsp + 8 * 2]
	push 2
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c5f:
	enter 0, 0
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_57]	; free var make-vector
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 2	; new rib
	call malloc
	push rax
	mov rdi, 8 * 2	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c60:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 1
	je .L_lambda_simple_env_end_3c60
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c60
.L_lambda_simple_env_end_3c60:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c60:	; copy params
	cmp rsi, 2
	je .L_lambda_simple_params_end_3c60
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c60
.L_lambda_simple_params_end_3c60:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c60
	jmp .L_lambda_simple_end_3c60
.L_lambda_simple_code_3c60:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c60
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c60:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 1881
	push rax
	push 1	; arg count
	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 3	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c61:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 2
	je .L_lambda_simple_env_end_3c61
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c61
.L_lambda_simple_env_end_3c61:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c61:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c61
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c61
.L_lambda_simple_params_end_3c61:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c61
	jmp .L_lambda_simple_end_3c61
.L_lambda_simple_code_3c61:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c61
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c61:
	enter 0, 0
	mov rdi, 8	; sob_box
	call malloc
	mov rbx, PARAM(0)
	mov [rax], rbx
	mov PARAM(0), rax
	mov rax, sob_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 1	; new rib
	call malloc
	push rax
	mov rdi, 8 * 4	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c62:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 3
	je .L_lambda_simple_env_end_3c62
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c62
.L_lambda_simple_env_end_3c62:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c62:	; copy params
	cmp rsi, 1
	je .L_lambda_simple_params_end_3c62
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c62
.L_lambda_simple_params_end_3c62:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c62
	jmp .L_lambda_simple_end_3c62
.L_lambda_simple_code_3c62:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 1
	je .L_lambda_simple_arity_check_ok_3c62
	push qword [rsp + 8 * 2]
	push 1
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c62:
	enter 0, 0
	; preparing a non tail-call
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 0]	; bound var n
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d6
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, PARAM(0)	; param i
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 2]
	mov rax, qword [rax + 8 * 1]	; bound var thunk
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
	push rax
	push 3	; arg count
	mov rax, qword [free_var_55]	; free var vector-set!
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)

	; preparing a tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(0)	; param i
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	push 1	; arg count
	mov rax, ENV
	mov rax, qword [rax + 8 * 0]
	mov rax, qword [rax + 8 * 0]	; bound var run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eeb:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eeb
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eeb
.L_tc_recycle_frame_done_4eeb:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d6
.L_if_else_52d6:
	mov rax, ENV
	mov rax, qword [rax + 8 * 1]
	mov rax, qword [rax + 8 * 0]	; bound var vec
.L_if_end_52d6:
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c62:	; new closure is in rax
	push rax
	mov rax, PARAM(0)	; param run
	pop qword [rax]
	mov rax, sob_void

	; preparing a tail-call
	mov rax, L_constants + 2023
	push rax
	push 1	; arg count
	mov rax, PARAM(0)	; param run
	mov rax, qword [rax]
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eec:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eec
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eec
.L_tc_recycle_frame_done_4eec:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c61:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eed:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eed
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eed
.L_tc_recycle_frame_done_4eed:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(1)
.L_lambda_simple_end_3c60:	; new closure is in rax
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eee:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eee
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eee
.L_tc_recycle_frame_done_4eee:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(2)
.L_lambda_simple_end_3c5f:	; new closure is in rax
	mov qword [free_var_174], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c63:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c63
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c63
.L_lambda_simple_env_end_3c63:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c63:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c63
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c63
.L_lambda_simple_params_end_3c63:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c63
	jmp .L_lambda_simple_end_3c63
.L_lambda_simple_code_3c63:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 3
	je .L_lambda_simple_arity_check_ok_3c63
	push qword [rsp + 8 * 2]
	push 3
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c63:
	enter 0, 0
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	push 1	; arg count
	mov rax, qword [free_var_27]	; free var zero?
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d7
	mov rax, L_constants + 3469
	jmp .L_if_end_52d7
.L_if_else_52d7:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_122]	; free var <
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d8
	; preparing a tail-call
	; preparing a non tail-call
	mov rax, PARAM(2)	; param n
	push rax
	; preparing a non tail-call
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 2	; arg count
	mov rax, qword [free_var_120]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 3	; arg count
	mov rax, qword [free_var_175]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3469
	push rax
	push 2	; arg count
	mov rax, qword [free_var_115]	; free var +
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4eef:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4eef
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4eef
.L_tc_recycle_frame_done_4eef:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	jmp .L_if_end_52d8
.L_if_else_52d8:
	; preparing a non tail-call
	mov rax, PARAM(1)	; param b
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	push 2	; arg count
	mov rax, qword [free_var_126]	; free var =
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	cmp rax, sob_boolean_false
	je .L_if_else_52d9
	mov rax, L_constants + 3469
	jmp .L_if_end_52d9
.L_if_else_52d9:
	; preparing a tail-call
	; preparing a non tail-call
	; preparing a non tail-call
	mov rax, L_constants + 2158
	push rax
	mov rax, PARAM(2)	; param n
	push rax
	push 2	; arg count
	mov rax, qword [free_var_117]	; free var -
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, PARAM(0)	; param a
	push rax
	mov rax, PARAM(1)	; param b
	push rax
	push 3	; arg count
	mov rax, qword [free_var_175]	; free var logarithm
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)
	call SOB_CLOSURE_CODE(rax)
	push rax
	mov rax, L_constants + 3469
	push rax
	push 2	; arg count
	mov rax, qword [free_var_120]	; free var /
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 2 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ef0:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ef0
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ef0
.L_tc_recycle_frame_done_4ef0:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
.L_if_end_52d9:
.L_if_end_52d8:
.L_if_end_52d7:
	leave
	ret AND_KILL_FRAME(3)
.L_lambda_simple_end_3c63:	; new closure is in rax
	mov qword [free_var_175], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rdi, (1 + 8 + 8)	; sob closure
	call malloc
	push rax
	mov rdi, 8 * 0	; new rib
	call malloc
	push rax
	mov rdi, 8 * 1	; extended env
	call malloc
	mov rdi, ENV
	mov rsi, 0
	mov rdx, 1
.L_lambda_simple_env_loop_3c64:	; ext_env[i + 1] <-- env[i]
	cmp rsi, 0
	je .L_lambda_simple_env_end_3c64
	mov rcx, qword [rdi + 8 * rsi]
	mov qword [rax + 8 * rdx], rcx
	inc rsi
	inc rdx
	jmp .L_lambda_simple_env_loop_3c64
.L_lambda_simple_env_end_3c64:
	pop rbx
	mov rsi, 0
.L_lambda_simple_params_loop_3c64:	; copy params
	cmp rsi, 0
	je .L_lambda_simple_params_end_3c64
	mov rdx, qword [rbp + 8 * rsi + 8 * 4]
	mov qword [rbx + 8 * rsi], rdx
	inc rsi
	jmp .L_lambda_simple_params_loop_3c64
.L_lambda_simple_params_end_3c64:
	mov qword [rax], rbx	; ext_env[0] <-- new_rib 
	mov rbx, rax
	pop rax
	mov byte [rax], T_closure
	mov SOB_CLOSURE_ENV(rax), rbx
	mov SOB_CLOSURE_CODE(rax), .L_lambda_simple_code_3c64
	jmp .L_lambda_simple_end_3c64
.L_lambda_simple_code_3c64:	; lambda-simple body
	cmp qword [rsp + 8 * 2], 0
	je .L_lambda_simple_arity_check_ok_3c64
	push qword [rsp + 8 * 2]
	push 0
	jmp L_error_incorrect_arity_simple
.L_lambda_simple_arity_check_ok_3c64:
	enter 0, 0
	; preparing a tail-call
	mov rax, L_constants + 3494
	push rax
	push 1	; arg count
	mov rax, qword [free_var_15]	; free var write-char
	cmp byte [rax], T_undefined
	je L_error_fvar_undefined
	cmp byte [rax], T_closure
	jne L_error_non_closure
	push SOB_CLOSURE_ENV(rax)

	; recycling the current frame
	push qword [rbp + 8 * 1]	; preserve old return address
	push qword [rbp + 8 * 0]	; preserve old frame-pointer
	mov rcx, 1 + 4
	mov rbx, COUNT
	lea rbx, [rbp + 8 * rbx + 8 * 3]
	lea rdx, [rbp - 8 * 1]
.L_tc_recycle_frame_loop_4ef1:
	cmp rcx, 0
	je .L_tc_recycle_frame_done_4ef1
	mov rsi, qword [rdx]
	mov qword [rbx], rsi
	dec rcx
	sub rbx, 8 * 1
	sub rdx, 8 * 1
	jmp .L_tc_recycle_frame_loop_4ef1
.L_tc_recycle_frame_done_4ef1:
	lea rsp, [rbx + 8 * 1]
	pop rbp	; the proc will restore it!
	jmp SOB_CLOSURE_CODE(rax)
	leave
	ret AND_KILL_FRAME(0)
.L_lambda_simple_end_3c64:	; new closure is in rax
	mov qword [free_var_176], rax
	mov rax, sob_void

	mov rdi, rax
	call print_sexpr_if_not_void

	mov rax, L_constants + 1

	mov rdi, rax
	call print_sexpr_if_not_void

        mov rdi, fmt_memory_usage
        mov rsi, qword [top_of_memory]
        sub rsi, memory
        mov rax, 0
        ENTER
        call printf
        LEAVE
	leave
	ret

L_error_fvar_undefined:
        push rax
        mov rdi, qword [stderr]  ; destination
        mov rsi, fmt_undefined_free_var_1
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        pop rax
        mov rax, qword [rax + 1] ; string
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rsi, 1               ; sizeof(char)
        mov rdx, qword [rax + 1] ; string-length
        mov rcx, qword [stderr]  ; destination
        mov rax, 0
        ENTER
        call fwrite
        LEAVE
        mov rdi, [stderr]       ; destination
        mov rsi, fmt_undefined_free_var_2
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -10
        call exit

L_error_non_closure:
        mov rdi, qword [stderr]
        mov rsi, fmt_non_closure
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -2
        call exit

L_error_improper_list:
	mov rdi, qword [stderr]
	mov rsi, fmt_error_improper_list
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
	mov rax, -7
	call exit

L_error_incorrect_arity_simple:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_simple
        jmp L_error_incorrect_arity_common
L_error_incorrect_arity_opt:
        mov rdi, qword [stderr]
        mov rsi, fmt_incorrect_arity_opt
L_error_incorrect_arity_common:
        pop rdx
        pop rcx
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -6
        call exit

section .data
fmt_undefined_free_var_1:
        db `!!! The free variable \0`
fmt_undefined_free_var_2:
        db ` was used before it was defined.\n\0`
fmt_incorrect_arity_simple:
        db `!!! Expected %ld arguments, but given %ld\n\0`
fmt_incorrect_arity_opt:
        db `!!! Expected at least %ld arguments, but given %ld\n\0`
fmt_memory_usage:
        db `\n!!! Used %ld bytes of dynamically-allocated memory\n\n\0`
fmt_non_closure:
        db `!!! Attempting to apply a non-closure!\n\0`
fmt_error_improper_list:
	db `!!! The argument is not a proper list!\n\0`

section .bss
memory:
	resb gbytes(1)

section .data
top_of_memory:
        dq memory

section .text
malloc:
        mov rax, qword [top_of_memory]
        add qword [top_of_memory], rdi
        ret

L_code_ptr_break:
        cmp qword [rsp + 8 * 2], 0
        jne L_error_arg_count_0
        int3
        mov rax, sob_void
        ret AND_KILL_FRAME(0)        

L_code_ptr_frame:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0

        mov rdi, fmt_frame
        mov rsi, qword [rbp]    ; old rbp
        mov rdx, qword [rsi + 8*1] ; ret addr
        mov rcx, qword [rsi + 8*2] ; lexical environment
        mov r8, qword [rsi + 8*3] ; count
        lea r9, [rsi + 8*4]       ; address of argument 0
        push 0
        push r9
        push r8                   ; we'll use it when printing the params
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

.L:
        mov rcx, qword [rsp]
        cmp rcx, 0
        je .L_out
        mov rdi, fmt_frame_param_prefix
        mov rsi, qword [rsp + 8*2]
        mov rax, 0
        
        ENTER
        call printf
        LEAVE

        mov rcx, qword [rsp]
        dec rcx
        mov qword [rsp], rcx    ; dec arg count
        inc qword [rsp + 8*2]   ; increment index of current arg
        mov rdi, qword [rsp + 8*1] ; addr of addr current arg
        lea r9, [rdi + 8]          ; addr of next arg
        mov qword [rsp + 8*1], r9  ; backup addr of next arg
        mov rdi, qword [rdi]       ; addr of current arg
        call print_sexpr
        mov rdi, fmt_newline
        mov rax, 0
        ENTER
        call printf
        LEAVE
        jmp .L
.L_out:
        mov rdi, fmt_frame_continue
        mov rax, 0
        ENTER
        call printf
        call getchar
        LEAVE
        
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(0)
        
print_sexpr_if_not_void:
	cmp rdi, sob_void
	je .done
	call print_sexpr
	mov rdi, fmt_newline
	mov rax, 0
	ENTER
	call printf
	LEAVE
.done:
	ret

section .data
fmt_frame:
        db `RBP = %p; ret addr = %p; lex env = %p; param count = %d\n\0`
fmt_frame_param_prefix:
        db `==[param %d]==> \0`
fmt_frame_continue:
        db `Hit <Enter> to continue...\0`
fmt_newline:
	db `\n\0`
fmt_void:
	db `#<void>\0`
fmt_nil:
	db `()\0`
fmt_boolean_false:
	db `#f\0`
fmt_boolean_true:
	db `#t\0`
fmt_char_backslash:
	db `#\\\\\0`
fmt_char_dquote:
	db `#\\"\0`
fmt_char_simple:
	db `#\\%c\0`
fmt_char_null:
	db `#\\nul\0`
fmt_char_bell:
	db `#\\bell\0`
fmt_char_backspace:
	db `#\\backspace\0`
fmt_char_tab:
	db `#\\tab\0`
fmt_char_newline:
	db `#\\newline\0`
fmt_char_formfeed:
	db `#\\page\0`
fmt_char_return:
	db `#\\return\0`
fmt_char_escape:
	db `#\\esc\0`
fmt_char_space:
	db `#\\space\0`
fmt_char_hex:
	db `#\\x%02X\0`
fmt_gensym:
        db `G%ld\0`
fmt_closure:
	db `#<closure at 0x%08X env=0x%08X code=0x%08X>\0`
fmt_lparen:
	db `(\0`
fmt_dotted_pair:
	db ` . \0`
fmt_rparen:
	db `)\0`
fmt_space:
	db ` \0`
fmt_empty_vector:
	db `#()\0`
fmt_vector:
	db `#(\0`
fmt_real:
	db `%f\0`
fmt_fraction:
	db `%ld/%ld\0`
fmt_zero:
	db `0\0`
fmt_int:
	db `%ld\0`
fmt_unknown_scheme_object_error:
	db `\n\n!!! Error: Unknown Scheme-object (RTTI 0x%02X) `
	db `at address 0x%08X\n\n\0`
fmt_dquote:
	db `\"\0`
fmt_string_char:
        db `%c\0`
fmt_string_char_7:
        db `\\a\0`
fmt_string_char_8:
        db `\\b\0`
fmt_string_char_9:
        db `\\t\0`
fmt_string_char_10:
        db `\\n\0`
fmt_string_char_11:
        db `\\v\0`
fmt_string_char_12:
        db `\\f\0`
fmt_string_char_13:
        db `\\r\0`
fmt_string_char_34:
        db `\\"\0`
fmt_string_char_92:
        db `\\\\\0`
fmt_string_char_hex:
        db `\\x%X;\0`

section .text

print_sexpr:
	enter 0, 0
	mov al, byte [rdi]
	cmp al, T_void
	je .Lvoid
	cmp al, T_nil
	je .Lnil
	cmp al, T_boolean_false
	je .Lboolean_false
	cmp al, T_boolean_true
	je .Lboolean_true
	cmp al, T_char
	je .Lchar
	cmp al, T_interned_symbol
	je .Linterned_symbol
        cmp al, T_uninterned_symbol
        je .Luninterned_symbol
	cmp al, T_pair
	je .Lpair
	cmp al, T_vector
	je .Lvector
	cmp al, T_closure
	je .Lclosure
	cmp al, T_real
	je .Lreal
	cmp al, T_fraction
	je .Lfraction
	cmp al, T_integer
	je .Linteger
	cmp al, T_string
	je .Lstring

	jmp .Lunknown_sexpr_type

.Lvoid:
	mov rdi, fmt_void
	jmp .Lemit

.Lnil:
	mov rdi, fmt_nil
	jmp .Lemit

.Lboolean_false:
	mov rdi, fmt_boolean_false
	jmp .Lemit

.Lboolean_true:
	mov rdi, fmt_boolean_true
	jmp .Lemit

.Lchar:
	mov al, byte [rdi + 1]
	cmp al, ' '
	jle .Lchar_whitespace
	cmp al, 92 		; backslash
	je .Lchar_backslash
	cmp al, '"'
	je .Lchar_dquote
	and rax, 255
	mov rdi, fmt_char_simple
	mov rsi, rax
	jmp .Lemit

.Lchar_whitespace:
	cmp al, 0
	je .Lchar_null
	cmp al, 7
	je .Lchar_bell
	cmp al, 8
	je .Lchar_backspace
	cmp al, 9
	je .Lchar_tab
	cmp al, 10
	je .Lchar_newline
	cmp al, 12
	je .Lchar_formfeed
	cmp al, 13
	je .Lchar_return
	cmp al, 27
	je .Lchar_escape
	and rax, 255
	cmp al, ' '
	je .Lchar_space
	mov rdi, fmt_char_hex
	mov rsi, rax
	jmp .Lemit	

.Lchar_backslash:
	mov rdi, fmt_char_backslash
	jmp .Lemit

.Lchar_dquote:
	mov rdi, fmt_char_dquote
	jmp .Lemit

.Lchar_null:
	mov rdi, fmt_char_null
	jmp .Lemit

.Lchar_bell:
	mov rdi, fmt_char_bell
	jmp .Lemit

.Lchar_backspace:
	mov rdi, fmt_char_backspace
	jmp .Lemit

.Lchar_tab:
	mov rdi, fmt_char_tab
	jmp .Lemit

.Lchar_newline:
	mov rdi, fmt_char_newline
	jmp .Lemit

.Lchar_formfeed:
	mov rdi, fmt_char_formfeed
	jmp .Lemit

.Lchar_return:
	mov rdi, fmt_char_return
	jmp .Lemit

.Lchar_escape:
	mov rdi, fmt_char_escape
	jmp .Lemit

.Lchar_space:
	mov rdi, fmt_char_space
	jmp .Lemit

.Lclosure:
	mov rsi, qword rdi
	mov rdi, fmt_closure
	mov rdx, SOB_CLOSURE_ENV(rsi)
	mov rcx, SOB_CLOSURE_CODE(rsi)
	jmp .Lemit

.Linterned_symbol:
	mov rdi, qword [rdi + 1] ; sob_string
	mov rsi, 1		 ; size = 1 byte
	mov rdx, qword [rdi + 1] ; length
	lea rdi, [rdi + 1 + 8]	 ; actual characters
	mov rcx, qword [stdout]	 ; FILE *
	ENTER
	call fwrite
	LEAVE
	jmp .Lend

.Luninterned_symbol:
        mov rsi, qword [rdi + 1] ; gensym counter
        mov rdi, fmt_gensym
        jmp .Lemit
	
.Lpair:
	push rdi
	mov rdi, fmt_lparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp] 	; pair
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi 		; pair
	mov rdi, SOB_PAIR_CDR(rdi)
.Lcdr:
	mov al, byte [rdi]
	cmp al, T_nil
	je .Lcdr_nil
	cmp al, T_pair
	je .Lcdr_pair
	push rdi
	mov rdi, fmt_dotted_pair
	mov rax, 0
        ENTER
	call printf
        LEAVE
	pop rdi
	call print_sexpr
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_nil:
	mov rdi, fmt_rparen
	mov rax, 0
        ENTER
	call printf
        LEAVE
	leave
	ret

.Lcdr_pair:
	push rdi
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	mov rdi, SOB_PAIR_CAR(rdi)
	call print_sexpr
	pop rdi
	mov rdi, SOB_PAIR_CDR(rdi)
	jmp .Lcdr

.Lvector:
	mov rax, qword [rdi + 1] ; length
	cmp rax, 0
	je .Lvector_empty
	push rdi
	mov rdi, fmt_vector
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rdi, qword [rsp]
	push qword [rdi + 1]
	push 1
	mov rdi, qword [rdi + 1 + 8] ; v[0]
	call print_sexpr
.Lvector_loop:
	; [rsp] index
	; [rsp + 8*1] limit
	; [rsp + 8*2] vector
	mov rax, qword [rsp]
	cmp rax, qword [rsp + 8*1]
	je .Lvector_end
	mov rdi, fmt_space
	mov rax, 0
        ENTER
	call printf
        LEAVE
	mov rax, qword [rsp]
	mov rbx, qword [rsp + 8*2]
	mov rdi, qword [rbx + 1 + 8 + 8 * rax] ; v[i]
	call print_sexpr
	inc qword [rsp]
	jmp .Lvector_loop

.Lvector_end:
	add rsp, 8*3
	mov rdi, fmt_rparen
	jmp .Lemit	

.Lvector_empty:
	mov rdi, fmt_empty_vector
	jmp .Lemit

.Lreal:
	push qword [rdi + 1]
	movsd xmm0, qword [rsp]
	add rsp, 8*1
	mov rdi, fmt_real
	mov rax, 1
	ENTER
	call printf
	LEAVE
	jmp .Lend

.Lfraction:
	mov rsi, qword [rdi + 1]
	mov rdx, qword [rdi + 1 + 8]
	cmp rsi, 0
	je .Lrat_zero
	cmp rdx, 1
	je .Lrat_int
	mov rdi, fmt_fraction
	jmp .Lemit

.Lrat_zero:
	mov rdi, fmt_zero
	jmp .Lemit

.Lrat_int:
	mov rdi, fmt_int
	jmp .Lemit

.Linteger:
	mov rsi, qword [rdi + 1]
	mov rdi, fmt_int
	jmp .Lemit

.Lstring:
	lea rax, [rdi + 1 + 8]
	push rax
	push qword [rdi + 1]
	mov rdi, fmt_dquote
	mov rax, 0
	ENTER
	call printf
	LEAVE
.Lstring_loop:
	; qword [rsp]: limit
	; qword [rsp + 8*1]: char *
	cmp qword [rsp], 0
	je .Lstring_end
	mov rax, qword [rsp + 8*1]
	mov al, byte [rax]
	and rax, 255
	cmp al, 7
        je .Lstring_char_7
        cmp al, 8
        je .Lstring_char_8
        cmp al, 9
        je .Lstring_char_9
        cmp al, 10
        je .Lstring_char_10
        cmp al, 11
        je .Lstring_char_11
        cmp al, 12
        je .Lstring_char_12
        cmp al, 13
        je .Lstring_char_13
        cmp al, 34
        je .Lstring_char_34
        cmp al, 92              ; \
        je .Lstring_char_92
        cmp al, ' '
        jl .Lstring_char_hex
        mov rdi, fmt_string_char
        mov rsi, rax
.Lstring_char_emit:
        mov rax, 0
        ENTER
        call printf
        LEAVE
        dec qword [rsp]
        inc qword [rsp + 8*1]
        jmp .Lstring_loop

.Lstring_char_7:
        mov rdi, fmt_string_char_7
        jmp .Lstring_char_emit

.Lstring_char_8:
        mov rdi, fmt_string_char_8
        jmp .Lstring_char_emit
        
.Lstring_char_9:
        mov rdi, fmt_string_char_9
        jmp .Lstring_char_emit

.Lstring_char_10:
        mov rdi, fmt_string_char_10
        jmp .Lstring_char_emit

.Lstring_char_11:
        mov rdi, fmt_string_char_11
        jmp .Lstring_char_emit

.Lstring_char_12:
        mov rdi, fmt_string_char_12
        jmp .Lstring_char_emit

.Lstring_char_13:
        mov rdi, fmt_string_char_13
        jmp .Lstring_char_emit

.Lstring_char_34:
        mov rdi, fmt_string_char_34
        jmp .Lstring_char_emit

.Lstring_char_92:
        mov rdi, fmt_string_char_92
        jmp .Lstring_char_emit

.Lstring_char_hex:
        mov rdi, fmt_string_char_hex
        mov rsi, rax
        jmp .Lstring_char_emit        

.Lstring_end:
	add rsp, 8 * 2
	mov rdi, fmt_dquote
	jmp .Lemit

.Lunknown_sexpr_type:
	mov rsi, fmt_unknown_scheme_object_error
	and rax, 255
	mov rdx, rax
	mov rcx, rdi
	mov rdi, qword [stderr]
	mov rax, 0
        ENTER
	call fprintf
        LEAVE
        leave
        ret

.Lemit:
	mov rax, 0
        ENTER
	call printf
        LEAVE
	jmp .Lend

.Lend:
	LEAVE
	ret

;;; rdi: address of free variable
;;; rsi: address of code-pointer
bind_primitive:
        enter 0, 0
        push rdi
        mov rdi, (1 + 8 + 8)
        call malloc
        pop rdi
        mov byte [rax], T_closure
        mov SOB_CLOSURE_ENV(rax), 0 ; dummy, lexical environment
        mov SOB_CLOSURE_CODE(rax), rsi ; code pointer
        mov qword [rdi], rax
        mov rax, sob_void
        leave
        ret

L_code_ptr_ash:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_integer(rdi)
        mov rcx, PARAM(1)
        assert_integer(rcx)
        mov rdi, qword [rdi + 1]
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl .L_negative
.L_loop_positive:
        cmp rcx, 0
        je .L_exit
        sal rdi, cl
        shr rcx, 8
        jmp .L_loop_positive
.L_negative:
        neg rcx
.L_loop_negative:
        cmp rcx, 0
        je .L_exit
        sar rdi, cl
        shr rcx, 8
        jmp .L_loop_negative
.L_exit:
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logand:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        and rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        or rdi, qword [r9 + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_logxor:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_integer(r8)
        mov r9, PARAM(1)
        assert_integer(r9)
        mov rdi, qword [r8 + 1]
        xor rdi, qword [r9 + 1]
        call make_integer
        LEAVE
        ret AND_KILL_FRAME(2)

L_code_ptr_lognot:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, qword [r8 + 1]
        not rdi
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_bin_apply:
        cmp qword [rsp + 8 * 2], 2
        jne L_error_arg_count_2
        mov r12, qword [rsp + 8 * 3]
        assert_closure(r12)
        lea r10, [rsp + 8 * 4]
        mov r11, qword [r10]
        mov r9, qword [rsp]
        mov rcx, 0
        mov rsi, r11
.L0:
        cmp rsi, sob_nil
        je .L0_out
        assert_pair(rsi)
        inc rcx
        mov rsi, SOB_PAIR_CDR(rsi)
        jmp .L0
.L0_out:
        lea rbx, [8 * (rcx - 2)]
        sub rsp, rbx
        mov rdi, rsp
        cld
        ; place ret addr
        mov rax, r9
        stosq
        ; place env_f
        mov rax, SOB_CLOSURE_ENV(r12)
        stosq
        ; place COUNT = rcx
        mov rax, rcx
        stosq
.L1:
        cmp rcx, 0
        je .L1_out
        mov rax, SOB_PAIR_CAR(r11)
        stosq
        mov r11, SOB_PAIR_CDR(r11)
        dec rcx
        jmp .L1
.L1_out:
        sub rdi, 8*1
        cmp r10, rdi
        jne .L_error_apply_stack_corrupted
        jmp SOB_CLOSURE_CODE(r12)
.L_error_apply_stack_corrupted:
        int3

L_code_ptr_is_null:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_nil
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_pair:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_pair
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_void:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_void
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_char
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_string:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_string
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        and byte [r8], T_symbol
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_uninterned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        cmp byte [r8], T_uninterned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_interned_symbol:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_interned_symbol
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_gensym:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        inc qword [gensym_count]
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_uninterned_symbol
        mov rcx, qword [gensym_count]
        mov qword [rax + 1], rcx
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_vector:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_vector
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_closure:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_closure
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_real
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_fraction
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_boolean
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_boolean_false:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_false
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_boolean_true:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        cmp bl, T_boolean_true
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_number:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_number
        jz .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_is_collection:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        mov bl, byte [rax]
        and bl, T_collection
        je .L_false
        mov rax, sob_boolean_true
        jmp .L_end
.L_false:
        mov rax, sob_boolean_false
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_cons:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_pair
        mov rbx, PARAM(0)
        mov SOB_PAIR_CAR(rax), rbx
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_display_sexpr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rdi, PARAM(0)
        call print_sexpr
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_write_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, SOB_CHAR_VALUE(rax)
        and rax, 255
        mov rdi, fmt_char
        mov rsi, rax
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_car:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CAR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_cdr:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rax, SOB_PAIR_CDR(rax)
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_string_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_string(rax)
        mov rdi, SOB_STRING_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_vector_length:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_vector(rax)
        mov rdi, SOB_VECTOR_LENGTH(rax)
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_real_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rbx, PARAM(0)
        assert_real(rbx)
        movsd xmm0, qword [rbx + 1]
        cvttsd2si rdi, xmm0
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_exit:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        mov rax, 0
        call exit

L_code_ptr_integer_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_fraction_to_real:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        push qword [rax + 1]
        cvtsi2sd xmm0, qword [rsp]
        push qword [rax + 1 + 8]
        cvtsi2sd xmm1, qword [rsp]
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_char_to_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_char(rax)
        mov al, byte [rax + 1]
        and rax, 255
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_fraction:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov r8, PARAM(0)
        assert_integer(r8)
        mov rdi, (1 + 8 + 8)
        call malloc
        mov rbx, qword [r8 + 1]
        mov byte [rax], T_fraction
        mov qword [rax + 1], rbx
        mov qword [rax + 1 + 8], 1
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_integer_to_char:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_integer(rax)
        mov rbx, qword [rax + 1]
        cmp rbx, 0
        jle L_error_integer_range
        cmp rbx, 256
        jge L_error_integer_range
        mov rdi, (1 + 1)
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_trng:
        enter 0, 0
        cmp COUNT, 0
        jne L_error_arg_count_0
        rdrand rdi
        shr rdi, 1
        call make_integer
        leave
        ret AND_KILL_FRAME(0)

L_code_ptr_is_zero:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        je .L_integer
        cmp byte [rax], T_fraction
        je .L_fraction
        cmp byte [rax], T_real
        je .L_real
        jmp L_error_incorrect_type
.L_integer:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_fraction:
        cmp qword [rax + 1], 0
        je .L_zero
        jmp .L_not_zero
.L_real:
        pxor xmm0, xmm0
        push qword [rax + 1]
        movsd xmm1, qword [rsp]
        ucomisd xmm0, xmm1
        je .L_zero
.L_not_zero:
        mov rax, sob_boolean_false
        jmp .L_end
.L_zero:
        mov rax, sob_boolean_true
.L_end:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_integer:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        cmp byte [rax], T_integer
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_raw_bin_add_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        addsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        subsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        mulsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rbx, PARAM(0)
        assert_real(rbx)
        mov rcx, PARAM(1)
        assert_real(rcx)
        movsd xmm0, qword [rbx + 1]
        movsd xmm1, qword [rcx + 1]
        pxor xmm2, xmm2
        ucomisd xmm1, xmm2
        je L_error_division_by_zero
        divsd xmm0, xmm1
        call make_real
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_add_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	add rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)
	
L_code_ptr_raw_bin_add_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        add rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	sub rdi, qword [r9 + 1]
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_sub_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1]     ; num2
        cqo
        imul rbx
        sub rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	cqo
	mov rax, qword [r8 + 1]
	mul qword [r9 + 1]
	mov rdi, rax
	call make_integer
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_mul_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1 + 8] ; den2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_bin_div_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r9 + 1]
	cmp rdi, 0
	je L_error_division_by_zero
	mov rsi, qword [r8 + 1]
	call normalize_fraction
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_bin_div_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov r8, PARAM(0)
        assert_fraction(r8)
        mov r9, PARAM(1)
        assert_fraction(r9)
        cmp qword [r9 + 1], 0
        je L_error_division_by_zero
        mov rax, qword [r8 + 1] ; num1
        mov rbx, qword [r9 + 1 + 8] ; den 2
        cqo
        imul rbx
        mov rsi, rax
        mov rax, qword [r8 + 1 + 8] ; den1
        mov rbx, qword [r9 + 1] ; num2
        cqo
        imul rbx
        mov rdi, rax
        call normalize_fraction
        leave
        ret AND_KILL_FRAME(2)
        
normalize_fraction:
        push rsi
        push rdi
        call gcd
        mov rbx, rax
        pop rax
        cqo
        idiv rbx
        mov r8, rax
        pop rax
        cqo
        idiv rbx
        mov r9, rax
        cmp r9, 0
        je .L_zero
        cmp r8, 1
        je .L_int
        mov rdi, (1 + 8 + 8)
        call malloc
        mov byte [rax], T_fraction
        mov qword [rax + 1], r9
        mov qword [rax + 1 + 8], r8
        ret
.L_zero:
        mov rdi, 0
        call make_integer
        ret
.L_int:
        mov rdi, r9
        call make_integer
        ret

iabs:
        mov rax, rdi
        cmp rax, 0
        jl .Lneg
        ret
.Lneg:
        neg rax
        ret

gcd:
        call iabs
        mov rbx, rax
        mov rdi, rsi
        call iabs
        cmp rax, 0
        jne .L0
        xchg rax, rbx
.L0:
        cmp rbx, 0
        je .L1
        cqo
        div rbx
        mov rax, rdx
        xchg rax, rbx
        jmp .L0
.L1:
        ret

L_code_ptr_error:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_interned_symbol(rsi)
        mov rsi, PARAM(1)
        assert_string(rsi)
        mov rdi, fmt_scheme_error_part_1
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rdi, PARAM(0)
        call print_sexpr
        mov rdi, fmt_scheme_error_part_2
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, PARAM(1)       ; sob_string
        mov rsi, 1              ; size = 1 byte
        mov rdx, qword [rax + 1] ; length
        lea rdi, [rax + 1 + 8]   ; actual characters
        mov rcx, qword [stdout]  ; FILE*
	ENTER
        call fwrite
	LEAVE
        mov rdi, fmt_scheme_error_part_3
        mov rax, 0
        ENTER
        call printf
        LEAVE
        mov rax, -9
        call exit

L_code_ptr_raw_less_than_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jae .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_less_than_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jge .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_less_than_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rsi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jge .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_rr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_real(rsi)
        mov rdi, PARAM(1)
        assert_real(rdi)
        movsd xmm0, qword [rsi + 1]
        movsd xmm1, qword [rdi + 1]
        comisd xmm0, xmm1
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_raw_equal_zz:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov r8, PARAM(0)
	assert_integer(r8)
	mov r9, PARAM(1)
	assert_integer(r9)
	mov rdi, qword [r8 + 1]
	cmp rdi, qword [r9 + 1]
	jne .L_false
	mov rax, sob_boolean_true
	jmp .L_exit
.L_false:
	mov rax, sob_boolean_false
.L_exit:
	leave
	ret AND_KILL_FRAME(2)

L_code_ptr_raw_equal_qq:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_fraction(rsi)
        mov rdi, PARAM(1)
        assert_fraction(rdi)
        mov rax, qword [rsi + 1] ; num1
        cqo
        imul qword [rdi + 1 + 8] ; den2
        mov rcx, rax
        mov rax, qword [rdi + 1 + 8] ; den1
        cqo
        imul qword [rdi + 1]          ; num2
        sub rcx, rax
        jne .L_false
        mov rax, sob_boolean_true
        jmp .L_exit
.L_false:
        mov rax, sob_boolean_false
.L_exit:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_quotient:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rax
        call make_integer
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_remainder:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rsi, PARAM(0)
        assert_integer(rsi)
        mov rdi, PARAM(1)
        assert_integer(rdi)
        mov rax, qword [rsi + 1]
        mov rbx, qword [rdi + 1]
        cmp rbx, 0
        je L_error_division_by_zero
        cqo
        idiv rbx
        mov rdi, rdx
        call make_integer
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_car:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CAR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_set_cdr:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rax, PARAM(0)
        assert_pair(rax)
        mov rbx, PARAM(1)
        mov SOB_PAIR_CDR(rax), rbx
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_string_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov bl, byte [rdi + 1 + 8 + 1 * rcx]
        mov rdi, 2
        call malloc
        mov byte [rax], T_char
        mov byte [rax + 1], bl
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_ref:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, [rdi + 1 + 8 + 8 * rcx]
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_vector_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_vector(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        mov qword [rdi + 1 + 8 + 8 * rcx], rax
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_string_set:
        enter 0, 0
        cmp COUNT, 3
        jne L_error_arg_count_3
        mov rdi, PARAM(0)
        assert_string(rdi)
        mov rsi, PARAM(1)
        assert_integer(rsi)
        mov rdx, qword [rdi + 1]
        mov rcx, qword [rsi + 1]
        cmp rcx, rdx
        jge L_error_integer_range
        cmp rcx, 0
        jl L_error_integer_range
        mov rax, PARAM(2)
        assert_char(rax)
        mov al, byte [rax + 1]
        mov byte [rdi + 1 + 8 + 1 * rcx], al
        mov rax, sob_void
        leave
        ret AND_KILL_FRAME(3)

L_code_ptr_make_vector:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        lea rdi, [1 + 8 + 8 * rcx]
        call malloc
        mov byte [rax], T_vector
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov qword [rax + 1 + 8 + 8 * r8], rdx
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)
        
L_code_ptr_make_string:
        enter 0, 0
        cmp COUNT, 2
        jne L_error_arg_count_2
        mov rcx, PARAM(0)
        assert_integer(rcx)
        mov rcx, qword [rcx + 1]
        cmp rcx, 0
        jl L_error_integer_range
        mov rdx, PARAM(1)
        assert_char(rdx)
        mov dl, byte [rdx + 1]
        lea rdi, [1 + 8 + 1 * rcx]
        call malloc
        mov byte [rax], T_string
        mov qword [rax + 1], rcx
        mov r8, 0
.L0:
        cmp r8, rcx
        je .L1
        mov byte [rax + 1 + 8 + 1 * r8], dl
        inc r8
        jmp .L0
.L1:
        leave
        ret AND_KILL_FRAME(2)

L_code_ptr_numerator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)
        
L_code_ptr_denominator:
        enter 0, 0
        cmp COUNT, 1
        jne L_error_arg_count_1
        mov rax, PARAM(0)
        assert_fraction(rax)
        mov rdi, qword [rax + 1 + 8]
        call make_integer
        leave
        ret AND_KILL_FRAME(1)

L_code_ptr_is_eq:
	enter 0, 0
	cmp COUNT, 2
	jne L_error_arg_count_2
	mov rdi, PARAM(0)
	mov rsi, PARAM(1)
	cmp rdi, rsi
	je .L_eq_true
	mov dl, byte [rdi]
	cmp dl, byte [rsi]
	jne .L_eq_false
	cmp dl, T_char
	je .L_char
	cmp dl, T_interned_symbol
	je .L_interned_symbol
        cmp dl, T_uninterned_symbol
        je .L_uninterned_symbol
	cmp dl, T_real
	je .L_real
	cmp dl, T_fraction
	je .L_fraction
	jmp .L_eq_false
.L_fraction:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
	jne .L_eq_false
	mov rax, qword [rsi + 1 + 8]
	cmp rax, qword [rdi + 1 + 8]
	jne .L_eq_false
	jmp .L_eq_true
.L_real:
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_interned_symbol:
	; never reached, because interned_symbols are static!
	; but I'm keeping it in case, I'll ever change
	; the implementation
	mov rax, qword [rsi + 1]
	cmp rax, qword [rdi + 1]
.L_uninterned_symbol:
        mov r8, qword [rdi + 1]
        cmp r8, qword [rsi + 1]
        jne .L_eq_false
        jmp .L_eq_true
.L_char:
	mov bl, byte [rsi + 1]
	cmp bl, byte [rdi + 1]
	jne .L_eq_false
.L_eq_true:
	mov rax, sob_boolean_true
	jmp .L_eq_exit
.L_eq_false:
	mov rax, sob_boolean_false
.L_eq_exit:
	leave
	ret AND_KILL_FRAME(2)

make_real:
        enter 0, 0
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_real
        movsd qword [rax + 1], xmm0
        leave 
        ret
        
make_integer:
        enter 0, 0
        mov rsi, rdi
        mov rdi, (1 + 8)
        call malloc
        mov byte [rax], T_integer
        mov qword [rax + 1], rsi
        leave
        ret
        
L_error_integer_range:
        mov rdi, qword [stderr]
        mov rsi, fmt_integer_range
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -5
        call exit

L_error_arg_count_0:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_0
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_1:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_1
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_2:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_2
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_12:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_12
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit

L_error_arg_count_3:
        mov rdi, qword [stderr]
        mov rsi, fmt_arg_count_3
        mov rdx, COUNT
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -3
        call exit
        
L_error_incorrect_type:
        mov rdi, qword [stderr]
        mov rsi, fmt_type
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -4
        call exit

L_error_division_by_zero:
        mov rdi, qword [stderr]
        mov rsi, fmt_division_by_zero
        mov rax, 0
        ENTER
        call fprintf
        LEAVE
        mov rax, -8
        call exit

section .data
gensym_count:
        dq 0
fmt_char:
        db `%c\0`
fmt_arg_count_0:
        db `!!! Expecting zero arguments. Found %d\n\0`
fmt_arg_count_1:
        db `!!! Expecting one argument. Found %d\n\0`
fmt_arg_count_12:
        db `!!! Expecting one required and one optional argument. Found %d\n\0`
fmt_arg_count_2:
        db `!!! Expecting two arguments. Found %d\n\0`
fmt_arg_count_3:
        db `!!! Expecting three arguments. Found %d\n\0`
fmt_type:
        db `!!! Function passed incorrect type\n\0`
fmt_integer_range:
        db `!!! Incorrect integer range\n\0`
fmt_division_by_zero:
        db `!!! Division by zero\n\0`
fmt_scheme_error_part_1:
        db `\n!!! The procedure \0`
fmt_scheme_error_part_2:
        db ` asked to terminate the program\n`
        db `    with the following message:\n\n\0`
fmt_scheme_error_part_3:
        db `\n\nGoodbye!\n\n\0`