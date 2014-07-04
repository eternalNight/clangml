(* Clang AST pretty printer *)

open Ast
open Util

let string_of_language = function
  | Lang_C -> "C"
  | Lang_CXX -> "C++"

let string_of_access_specifier = function
  | AS_public -> "public"
  | AS_protected -> "protected"
  | AS_private -> "private"
  | AS_none -> ""

let string_of_overloaded_operator_kind = function
  | OO_New                  -> "new"
  | OO_Delete               -> "delete"
  | OO_Array_New            -> "new[]"
  | OO_Array_Delete         -> "delete[]"
  | OO_Plus                 -> "+"
  | OO_Minus                -> "-"
  | OO_Star                 -> "*"
  | OO_Slash                -> "/"
  | OO_Percent              -> "%"
  | OO_Caret                -> "^"
  | OO_Amp                  -> "&"
  | OO_Pipe                 -> "|"
  | OO_Tilde                -> "~"
  | OO_Exclaim              -> "!"
  | OO_Equal                -> "="
  | OO_Less                 -> "<"
  | OO_Greater              -> ">"
  | OO_PlusEqual            -> "+="
  | OO_MinusEqual           -> "-="
  | OO_StarEqual            -> "*="
  | OO_SlashEqual           -> "/="
  | OO_PercentEqual         -> "%="
  | OO_CaretEqual           -> "^="
  | OO_AmpEqual             -> "&="
  | OO_PipeEqual            -> "|="
  | OO_LessLess             -> "<<"
  | OO_GreaterGreater       -> ">>"
  | OO_LessLessEqual        -> "<<="
  | OO_GreaterGreaterEqual  -> ">>="
  | OO_EqualEqual           -> "=="
  | OO_ExclaimEqual         -> "!="
  | OO_LessEqual            -> "<="
  | OO_GreaterEqual         -> ">="
  | OO_AmpAmp               -> "&&"
  | OO_PipePipe             -> "||"
  | OO_PlusPlus             -> "++"
  | OO_MinusMinus           -> "--"
  | OO_Comma                -> ","
  | OO_ArrowStar            -> "->*"
  | OO_Arrow                -> "->"
  | OO_Call                 -> "()"
  | OO_Subscript            -> "[]"
  | OO_Conditional          -> "?"

let string_of_qualifier = function
  | TQ_Const -> "const"
  | TQ_Volatile -> "volatile"
  | TQ_Restrict -> "restrict"
  | TQ_Weak -> "weak"
  | TQ_Strong -> "strong"
  | TQ_OCL_ExplicitNone -> "no_lifetime"
  | TQ_OCL_Strong -> "strong_lifetime"
  | TQ_OCL_Weak -> "weak_lifetime"
  | TQ_OCL_Autoreleasing -> "autoreleasing"

let string_of_predefined_expr = function
  | PE_Func -> "__func__"
  | PE_Function -> "__FUNCTION__"
  | PE_LFunction -> "__LFUNCTION__"
  | PE_FuncDName -> "__FUNCDNAME__"
  | PE_PrettyFunction -> "__PRETTY_FUNCTION__"
  | PE_PrettyFunctionNoVirtual -> "__PRETTY_FUNCTION_NO_VIRTUAL__"

let string_of_tag_type_kind = function
  | TTK_Struct -> "struct"
  | TTK_Interface -> "__interface"
  | TTK_Union -> "union"
  | TTK_Class -> "class"
  | TTK_Enum -> "enum"

let string_of_elaborated_type_keyword = function
  | ETK_Struct -> "struct"
  | ETK_Interface -> "__interface"
  | ETK_Union -> "union"
  | ETK_Class -> "class"
  | ETK_Enum -> "enum"
  | ETK_Typename -> "typename"
  | ETK_None -> ""

let string_of_builtin_type = function
  | BT_Void -> "void"
  | BT_Bool -> "bool"
  | BT_Char_U -> "char_u"
  | BT_UChar -> "unsigned char"
  | BT_WChar_U -> "wchar_u"
  | BT_Char16 -> "char16_t"
  | BT_Char32 -> "char32_t"
  | BT_UShort -> "unsigned short"
  | BT_UInt -> "unsigned int"
  | BT_ULong -> "unsigned long"
  | BT_ULongLong -> "unsigned long long"
  | BT_UInt128 -> "__uint128"
  | BT_Char_S -> "char_s"
  | BT_SChar -> "signed char"
  | BT_WChar_S -> "wchar_s"
  | BT_Short -> "short"
  | BT_Int -> "int"
  | BT_Long -> "long"
  | BT_LongLong -> "long long"
  | BT_Int128 -> "__int128"
  | BT_Half -> "half"
  | BT_Float -> "float"
  | BT_Double -> "double"
  | BT_LongDouble -> "long double"
  | BT_NullPtr -> "nullptr_t"
  | BT_ObjCId -> "objcid"
  | BT_ObjCClass -> "objcclass"
  | BT_ObjCSel -> "objcsel"
  | BT_OCLImage1d -> "oclimage1d"
  | BT_OCLImage1dArray -> "oclimage1darray"
  | BT_OCLImage1dBuffer -> "oclimage1dbuffer"
  | BT_OCLImage2d -> "oclimage2d"
  | BT_OCLImage2dArray -> "oclimage2darray"
  | BT_OCLImage3d -> "oclimage3d"
  | BT_OCLSampler -> "oclsampler"
  | BT_OCLEvent -> "oclevent"
  | BT_Dependent -> "dependent"
  | BT_Overload -> "overload"
  | BT_BoundMember -> "boundmember"
  | BT_PseudoObject -> "pseudoobject"
  | BT_UnknownAny -> "unknownany"
  | BT_BuiltinFn -> "builtinfn"
  | BT_ARCUnbridgedCast -> "arcunbridgedcast"


let is_prefix = function
  | UO_PostInc
  | UO_PostDec -> false
  | _ -> true


let string_of_unary_op = function
  | UO_PostInc		-> "++"
  | UO_PostDec		-> "--"
  | UO_PreInc		-> "++"
  | UO_PreDec		-> "--"
  | UO_AddrOf		-> "&"
  | UO_Deref		-> "*"
  | UO_Plus		-> "+"
  | UO_Minus		-> "-"
  | UO_Not		-> "~"
  | UO_LNot		-> "!"
  | UO_Real		-> "__real"
  | UO_Imag		-> "__imag"
  | UO_Extension	-> "__extension__"


let string_of_binary_op = function
  | BO_PtrMemD		-> "->*"
  | BO_PtrMemI		-> "->*"
  | BO_Mul		-> "*"
  | BO_Div		-> "/"
  | BO_Rem		-> "%"
  | BO_Add		-> "+"
  | BO_Sub		-> "-"
  | BO_Shl		-> "<<"
  | BO_Shr		-> ">>"
  | BO_LT		-> "<"
  | BO_GT		-> ">"
  | BO_LE		-> "<="
  | BO_GE		-> ">="
  | BO_EQ		-> "=="
  | BO_NE		-> "!="
  | BO_And		-> "&"
  | BO_Xor		-> "^"
  | BO_Or		-> "|"
  | BO_LAnd		-> "&&"
  | BO_LOr		-> "||"
  | BO_Assign		-> "="
  | BO_Comma		-> ","

  | BO_MulAssign	-> "*="
  | BO_DivAssign	-> "/="
  | BO_RemAssign	-> "%="
  | BO_AddAssign	-> "+="
  | BO_SubAssign	-> "-="
  | BO_ShlAssign	-> "<<="
  | BO_ShrAssign	-> ">>="
  | BO_AndAssign	-> "&="
  | BO_OrAssign		-> "|="
  | BO_XorAssign	-> "^*"


let pp_option f fmt = function
  | None -> Format.pp_print_string fmt "<null>"
  | Some x -> f fmt x

let pp_sloc fmt ploc =
  if Sloc.is_valid_presumed ploc then
    Format.fprintf fmt "# %d \"%s\"\n"
      ploc.Sloc.loc_line
      ploc.Sloc.loc_filename
  else
    Format.pp_print_string fmt "# <invalid sloc>\n"


let rec pp_desg_ fmt = function
  | FieldDesignator name ->
      Format.fprintf fmt ".%s" name
  | ArrayDesignator index ->
      Format.fprintf fmt "[%a]"
        pp_expr index
  | ArrayRangeDesignator (left, right) ->
      Format.fprintf fmt "[%a ... %a]"
        pp_expr left
        pp_expr right

and pp_desg fmt desg =
  pp_desg_ fmt desg.dr


and pp_expr_ fmt = function
  | CharacterLiteral c -> Format.pp_print_string fmt (Char.escaped c)
  | IntegerLiteral i -> Format.pp_print_int fmt i
  | FloatingLiteral f -> Format.pp_print_float fmt f
  | StringLiteral s -> Format.fprintf fmt "\"%s\"" (String.escaped s)
  | UnaryOperator (op, e) ->
      if is_prefix op then
        Format.fprintf fmt "(%s %a)" (string_of_unary_op op) pp_expr e
      else
        Format.fprintf fmt "(%a %s)" pp_expr e (string_of_unary_op op)
  | BinaryOperator (op, e1, e2) ->
      Format.fprintf fmt "(%a %s %a)"
        pp_expr e1
        (string_of_binary_op op)
        pp_expr e2

  | DeclRefExpr name ->
      Format.pp_print_string fmt name
  | PredefinedExpr kind ->
      Format.pp_print_string fmt (string_of_predefined_expr kind)
  | ImplicitCastExpr (_, expr) ->
      Format.fprintf fmt "%a"
        pp_expr expr
  | CompoundLiteralExpr (ty, expr)
  | CStyleCastExpr (_, ty, expr) ->
      Format.fprintf fmt "(%a)%a"
        pp_tloc ty
        pp_expr expr
  | ParenExpr expr ->
      Format.fprintf fmt "(%a)"
        pp_expr expr
  | VAArgExpr (sub, ty) ->
      Format.fprintf fmt "va_arg (%a, %a)"
        pp_expr sub
        pp_tloc ty
  | CallExpr (callee, args) ->
      Format.fprintf fmt "%a (%a)"
        pp_expr callee
        (Formatx.pp_list pp_expr) args
  | MemberExpr (base, member, is_arrow) ->
      Format.fprintf fmt "%a%s%s"
        pp_expr base
        (if is_arrow then "->" else ".")
        member
  | ConditionalOperator (cond, true_expr, false_expr) ->
      Format.fprintf fmt "%a ? %a : %a"
        pp_expr cond
        pp_expr true_expr
        pp_expr false_expr
  | DesignatedInitExpr (designators, init) ->
      Format.fprintf fmt "%a = %a"
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_desg) designators
        pp_expr init
  | InitListExpr inits ->
      Format.fprintf fmt "{ %a }"
        (Formatx.pp_list pp_expr) inits
  | ImplicitValueInitExpr ->
      Format.pp_print_string fmt "<implicit value>"
  | ArraySubscriptExpr (base, idx) ->
      Format.fprintf fmt "%a[%a]"
        pp_expr base
        pp_expr idx
  | StmtExpr stmt ->
      Format.fprintf fmt "(%a)"
        pp_stmt stmt
  | AddrLabelExpr label ->
      Format.fprintf fmt "&&%s"
        label
  | OffsetOfExpr (ty, components) ->
      Format.fprintf fmt "%a (%a)"
        pp_tloc ty
        (Formatx.pp_list pp_offsetof_node) components

  | SizeOfExpr expr ->
      Format.fprintf fmt "sizeof %a"
        pp_expr expr
  | SizeOfType ty ->
      Format.fprintf fmt "sizeof (%a)"
        pp_tloc ty
  | AlignOfExpr expr ->
      Format.fprintf fmt "alignof %a"
        pp_expr expr
  | AlignOfType ty ->
      Format.fprintf fmt "alignof (%a)"
        pp_tloc ty
  | VecStepExpr expr ->
      Format.fprintf fmt "vec_step %a"
        pp_expr expr
  | VecStepType ty ->
      Format.fprintf fmt "vec_step (%a)"
        pp_tloc ty

  | CXXNullPtrLiteralExpr ->
      Format.fprintf fmt "nullptr"

  | ConvertVectorExpr -> Format.pp_print_string fmt "<ConvertVectorExpr>"
  | ArrayTypeTraitExpr -> Format.pp_print_string fmt "<ArrayTypeTraitExpr>"
  | AsTypeExpr -> Format.pp_print_string fmt "<AsTypeExpr>"
  | AtomicExpr -> Format.pp_print_string fmt "<AtomicExpr>"
  | BinaryConditionalOperator -> Format.pp_print_string fmt "<BinaryConditionalOperator>"
  | BinaryTypeTraitExpr -> Format.pp_print_string fmt "<BinaryTypeTraitExpr>"
  | BlockExpr -> Format.pp_print_string fmt "<BlockExpr>"
  | ChooseExpr -> Format.pp_print_string fmt "<ChooseExpr>"
  | CompoundAssignOperator -> Format.pp_print_string fmt "<CompoundAssignOperator>"
  | CUDAKernelCallExpr -> Format.pp_print_string fmt "<CUDAKernelCallExpr>"
  | CXXBindTemporaryExpr -> Format.pp_print_string fmt "<CXXBindTemporaryExpr>"
  | CXXBoolLiteralExpr -> Format.pp_print_string fmt "<CXXBoolLiteralExpr>"
  | CXXConstCastExpr -> Format.pp_print_string fmt "<CXXConstCastExpr>"
  | CXXConstructExpr -> Format.pp_print_string fmt "<CXXConstructExpr>"
  | CXXDefaultArgExpr -> Format.pp_print_string fmt "<CXXDefaultArgExpr>"
  | CXXDefaultInitExpr -> Format.pp_print_string fmt "<CXXDefaultInitExpr>"
  | CXXDeleteExpr -> Format.pp_print_string fmt "<CXXDeleteExpr>"
  | CXXDependentScopeMemberExpr -> Format.pp_print_string fmt "<CXXDependentScopeMemberExpr>"
  | CXXDynamicCastExpr -> Format.pp_print_string fmt "<CXXDynamicCastExpr>"
  | CXXFunctionalCastExpr -> Format.pp_print_string fmt "<CXXFunctionalCastExpr>"
  | CXXMemberCallExpr -> Format.pp_print_string fmt "<CXXMemberCallExpr>"
  | CXXNewExpr -> Format.pp_print_string fmt "<CXXNewExpr>"
  | CXXNoexceptExpr -> Format.pp_print_string fmt "<CXXNoexceptExpr>"
  | CXXOperatorCallExpr -> Format.pp_print_string fmt "<CXXOperatorCallExpr>"
  | CXXPseudoDestructorExpr -> Format.pp_print_string fmt "<CXXPseudoDestructorExpr>"
  | CXXReinterpretCastExpr -> Format.pp_print_string fmt "<CXXReinterpretCastExpr>"
  | CXXScalarValueInitExpr -> Format.pp_print_string fmt "<CXXScalarValueInitExpr>"
  | CXXStaticCastExpr -> Format.pp_print_string fmt "<CXXStaticCastExpr>"
  | CXXStdInitializerListExpr -> Format.pp_print_string fmt "<CXXStdInitializerListExpr>"
  | CXXTemporaryObjectExpr -> Format.pp_print_string fmt "<CXXTemporaryObjectExpr>"
  | CXXThisExpr -> Format.pp_print_string fmt "<CXXThisExpr>"
  | CXXThrowExpr -> Format.pp_print_string fmt "<CXXThrowExpr>"
  | CXXTypeidExpr -> Format.pp_print_string fmt "<CXXTypeidExpr>"
  | CXXUnresolvedConstructExpr -> Format.pp_print_string fmt "<CXXUnresolvedConstructExpr>"
  | CXXUuidofExpr -> Format.pp_print_string fmt "<CXXUuidofExpr>"
  | DependentScopeDeclRefExpr -> Format.pp_print_string fmt "<DependentScopeDeclRefExpr>"
  | ExpressionTraitExpr -> Format.pp_print_string fmt "<ExpressionTraitExpr>"
  | ExprWithCleanups -> Format.pp_print_string fmt "<ExprWithCleanups>"
  | ExtVectorElementExpr -> Format.pp_print_string fmt "<ExtVectorElementExpr>"
  | FunctionParmPackExpr -> Format.pp_print_string fmt "<FunctionParmPackExpr>"
  | GenericSelectionExpr -> Format.pp_print_string fmt "<GenericSelectionExpr>"
  | GNUNullExpr -> Format.pp_print_string fmt "<GNUNullExpr>"
  | ImaginaryLiteral -> Format.pp_print_string fmt "<ImaginaryLiteral>"
  | LambdaExpr -> Format.pp_print_string fmt "<LambdaExpr>"
  | MaterializeTemporaryExpr -> Format.pp_print_string fmt "<MaterializeTemporaryExpr>"
  | MSPropertyRefExpr -> Format.pp_print_string fmt "<MSPropertyRefExpr>"
  | ObjCArrayLiteral -> Format.pp_print_string fmt "<ObjCArrayLiteral>"
  | ObjCBoolLiteralExpr -> Format.pp_print_string fmt "<ObjCBoolLiteralExpr>"
  | ObjCBoxedExpr -> Format.pp_print_string fmt "<ObjCBoxedExpr>"
  | ObjCBridgedCastExpr -> Format.pp_print_string fmt "<ObjCBridgedCastExpr>"
  | ObjCDictionaryLiteral -> Format.pp_print_string fmt "<ObjCDictionaryLiteral>"
  | ObjCEncodeExpr -> Format.pp_print_string fmt "<ObjCEncodeExpr>"
  | ObjCIndirectCopyRestoreExpr -> Format.pp_print_string fmt "<ObjCIndirectCopyRestoreExpr>"
  | ObjCIsaExpr -> Format.pp_print_string fmt "<ObjCIsaExpr>"
  | ObjCIvarRefExpr -> Format.pp_print_string fmt "<ObjCIvarRefExpr>"
  | ObjCMessageExpr -> Format.pp_print_string fmt "<ObjCMessageExpr>"
  | ObjCPropertyRefExpr -> Format.pp_print_string fmt "<ObjCPropertyRefExpr>"
  | ObjCProtocolExpr -> Format.pp_print_string fmt "<ObjCProtocolExpr>"
  | ObjCSelectorExpr -> Format.pp_print_string fmt "<ObjCSelectorExpr>"
  | ObjCStringLiteral -> Format.pp_print_string fmt "<ObjCStringLiteral>"
  | ObjCSubscriptRefExpr -> Format.pp_print_string fmt "<ObjCSubscriptRefExpr>"
  | OpaqueValueExpr -> Format.pp_print_string fmt "<OpaqueValueExpr>"
  | PackExpansionExpr -> Format.pp_print_string fmt "<PackExpansionExpr>"
  | ParenListExpr -> Format.pp_print_string fmt "<ParenListExpr>"
  | PseudoObjectExpr -> Format.pp_print_string fmt "<PseudoObjectExpr>"
  | ShuffleVectorExpr -> Format.pp_print_string fmt "<ShuffleVectorExpr>"
  | SizeOfPackExpr -> Format.pp_print_string fmt "<SizeOfPackExpr>"
  | SubstNonTypeTemplateParmExpr -> Format.pp_print_string fmt "<SubstNonTypeTemplateParmExpr>"
  | SubstNonTypeTemplateParmPackExpr -> Format.pp_print_string fmt "<SubstNonTypeTemplateParmPackExpr>"
  | TypeTraitExpr -> Format.pp_print_string fmt "<TypeTraitExpr>"
  | UnaryTypeTraitExpr -> Format.pp_print_string fmt "<UnaryTypeTraitExpr>"
  | UnresolvedLookupExpr -> Format.pp_print_string fmt "<UnresolvedLookupExpr>"
  | UnresolvedMemberExpr -> Format.pp_print_string fmt "<UnresolvedMemberExpr>"
  | UserDefinedLiteral -> Format.pp_print_string fmt "<UserDefinedLiteral>"

and pp_expr fmt expr =
  pp_expr_ fmt expr.e

and pp_offsetof_node fmt = function
  | OON_Array expr      -> pp_expr fmt expr
  | OON_Field name      -> Format.fprintf fmt "field_name: %s" name
  | OON_Identifier name -> Format.fprintf fmt "field_id: %s" name
  | OON_Base spec       -> pp_cxx_base_specifier fmt spec

and pp_stmt_ fmt = function
  | NullStmt ->
      Format.pp_print_string fmt ";"
  | BreakStmt ->
      Format.pp_print_string fmt "break;"
  | ContinueStmt ->
      Format.pp_print_string fmt "continue;"
  | LabelStmt (name, sub) ->
      Format.fprintf fmt "%s: %a"
        name
        pp_stmt sub
  | GotoStmt name ->
      Format.fprintf fmt "goto %s;"
        name
  | ExprStmt e ->
      Format.fprintf fmt "%a;"
        pp_expr e
  | CompoundStmt ss ->
      Format.fprintf fmt "@\n@[<v2>{@\n%a@]@\n}"
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_stmt) ss
  | ReturnStmt None ->
      Format.fprintf fmt "return;"
  | ReturnStmt (Some e) ->
      Format.fprintf fmt "return %a;"
        pp_expr e
  | DefaultStmt sub ->
      Format.fprintf fmt "default: %a"
        pp_stmt sub
  | CaseStmt (lhs, None, sub) ->
      Format.fprintf fmt "case %a: %a"
        pp_expr lhs
        pp_stmt sub
  | CaseStmt (lhs, Some rhs, sub) ->
      Format.fprintf fmt "case %a ... %a: %a"
        pp_expr lhs
        pp_expr rhs
        pp_stmt sub
  | ForStmt (init, cond, inc, body) ->
      Format.fprintf fmt "for (%a%a;%a) %a"
        (pp_option pp_stmt) init
        (pp_option pp_expr) cond
        (pp_option pp_expr) inc
        pp_stmt body
  | WhileStmt (cond, body) ->
      Format.fprintf fmt "while (%a) %a"
        pp_expr cond
        pp_stmt body
  | DoStmt (body, cond) ->
      Format.fprintf fmt "do %a while (%a)"
        pp_stmt body
        pp_expr cond
  | SwitchStmt (cond, body) ->
      Format.fprintf fmt "switch (%a) %a"
        pp_expr cond
        pp_stmt body
  | IfStmt (cond, thn, None) ->
      Format.fprintf fmt "if (%a) %a"
        pp_expr cond
        pp_stmt thn
  | IfStmt (cond, thn, Some els) ->
      Format.fprintf fmt "if (%a) %a@\nelse %a"
        pp_expr cond
        pp_stmt thn
        pp_stmt els
  | DeclStmt decls ->
      Format.fprintf fmt "%a;"
        (Formatx.pp_list pp_decl) decls
  | GCCAsmStmt (asm_string, outputs, inputs, clobbers) ->
      Format.fprintf fmt "asm (%a:%a:%a:%a);"
        pp_expr asm_string
        (Formatx.pp_list pp_asm_arg) outputs
        (Formatx.pp_list pp_asm_arg) inputs
        (Formatx.pp_list Format.pp_print_string) clobbers
  | IndirectGotoStmt expr ->
      Format.fprintf fmt "goto *%a"
        pp_expr expr

  | OMPParallelDirective -> Format.pp_print_string fmt "<OMPParallelDirective>"
  | AttributedStmt -> Format.pp_print_string fmt "<AttributedStmt>"
  | CapturedStmt -> Format.pp_print_string fmt "<CapturedStmt>"
  | CXXCatchStmt -> Format.pp_print_string fmt "<CXXCatchStmt>"
  | CXXForRangeStmt -> Format.pp_print_string fmt "<CXXForRangeStmt>"
  | CXXTryStmt -> Format.pp_print_string fmt "<CXXTryStmt>"
  | MSAsmStmt -> Format.pp_print_string fmt "<MSAsmStmt>"
  | MSDependentExistsStmt -> Format.pp_print_string fmt "<MSDependentExistsStmt>"
  | ObjCAtCatchStmt -> Format.pp_print_string fmt "<ObjCAtCatchStmt>"
  | ObjCAtFinallyStmt -> Format.pp_print_string fmt "<ObjCAtFinallyStmt>"
  | ObjCAtSynchronizedStmt -> Format.pp_print_string fmt "<ObjCAtSynchronizedStmt>"
  | ObjCAtThrowStmt -> Format.pp_print_string fmt "<ObjCAtThrowStmt>"
  | ObjCAtTryStmt -> Format.pp_print_string fmt "<ObjCAtTryStmt>"
  | ObjCAutoreleasePoolStmt -> Format.pp_print_string fmt "<ObjCAutoreleasePoolStmt>"
  | ObjCForCollectionStmt -> Format.pp_print_string fmt "<ObjCForCollectionStmt>"
  | SEHExceptStmt -> Format.pp_print_string fmt "<SEHExceptStmt>"
  | SEHFinallyStmt -> Format.pp_print_string fmt "<SEHFinallyStmt>"
  | SEHTryStmt -> Format.pp_print_string fmt "<SEHTryStmt>"

and pp_stmt fmt stmt =
  pp_stmt_ fmt stmt.s

and pp_asm_arg fmt arg =
  Format.fprintf fmt "%s %a"
    arg.aa_constraint
    pp_expr arg.aa_expr

and pp_tloc_ fmt = function
  | QualifiedTypeLoc (unqual, quals, addr_space) ->
      Format.fprintf fmt "%a %a%s"
        pp_tloc unqual
        Formatx.(pp_list ~sep:(pp_sep "") pp_print_string)
          (List.map string_of_qualifier quals)
        (match addr_space with
         | None -> ""
         | Some aspace -> " addr_space_" ^ string_of_int aspace)
  | BuiltinTypeLoc bt ->
      Format.fprintf fmt "%s"
        (string_of_builtin_type bt)
  | TypedefTypeLoc name ->
      Format.fprintf fmt "%s"
        name
  | TypeOfExprTypeLoc expr ->
      Format.fprintf fmt "typeof (%a)"
        pp_expr expr
  | DecltypeTypeLoc expr ->
      Format.fprintf fmt "decltype (%a)"
        pp_expr expr
  | TypeOfTypeLoc ty ->
      Format.fprintf fmt "typeof (%a)"
        pp_tloc ty
  | ParenTypeLoc ty ->
      Format.fprintf fmt "(%a)"
        pp_tloc ty
  | PointerTypeLoc ty ->
      Format.fprintf fmt "%a ptr"
        pp_tloc ty
  | FunctionNoProtoTypeLoc ty ->
      Format.fprintf fmt "? -> %a"
        pp_tloc ty
  | FunctionProtoTypeLoc (ty, args) ->
      Format.fprintf fmt "(%a) -> %a"
        (Formatx.pp_list pp_decl) args
        pp_tloc ty
  | ConstantArrayTypeLoc (ty, size) ->
      Format.fprintf fmt "%a[%d]"
        pp_tloc ty
        size
  | VariableArrayTypeLoc (ty, size) ->
      Format.fprintf fmt "%a[%a]"
        pp_tloc ty
        pp_expr size
  | IncompleteArrayTypeLoc ty ->
      Format.fprintf fmt "%a[]"
        pp_tloc ty
  | ElaboratedTypeLoc ty ->
      Format.fprintf fmt "%a"
        pp_tloc ty
  | RecordTypeLoc (kind, name) ->
      Format.fprintf fmt "%s %s"
        (string_of_tag_type_kind kind)
        (if name = "" then "<anonymous>" else name)
  | EnumTypeLoc name ->
      Format.pp_print_string fmt
        (if name = "" then "<anonymous>" else name)

  | DecayedTypeLoc _ -> Format.pp_print_string fmt "<DecayedTypeLoc>"
  | AtomicTypeLoc -> Format.pp_print_string fmt "<AtomicTypeLoc>"
  | AttributedTypeLoc -> Format.pp_print_string fmt "<AttributedTypeLoc>"
  | AutoTypeLoc -> Format.pp_print_string fmt "<AutoTypeLoc>"
  | BlockPointerTypeLoc -> Format.pp_print_string fmt "<BlockPointerTypeLoc>"
  | ComplexTypeLoc -> Format.pp_print_string fmt "<ComplexTypeLoc>"
  | DependentNameTypeLoc -> Format.pp_print_string fmt "<DependentNameTypeLoc>"
  | DependentSizedArrayTypeLoc -> Format.pp_print_string fmt "<DependentSizedArrayTypeLoc>"
  | DependentSizedExtVectorTypeLoc -> Format.pp_print_string fmt "<DependentSizedExtVectorTypeLoc>"
  | DependentTemplateSpecializationTypeLoc -> Format.pp_print_string fmt "<DependentTemplateSpecializationTypeLoc>"
  | ExtVectorTypeLoc -> Format.pp_print_string fmt "<ExtVectorTypeLoc>"
  | InjectedClassNameTypeLoc -> Format.pp_print_string fmt "<InjectedClassNameTypeLoc>"
  | LValueReferenceTypeLoc -> Format.pp_print_string fmt "<LValueReferenceTypeLoc>"
  | MemberPointerTypeLoc -> Format.pp_print_string fmt "<MemberPointerTypeLoc>"
  | ObjCInterfaceTypeLoc -> Format.pp_print_string fmt "<ObjCInterfaceTypeLoc>"
  | ObjCObjectTypeLoc -> Format.pp_print_string fmt "<ObjCObjectTypeLoc>"
  | ObjCObjectPointerTypeLoc -> Format.pp_print_string fmt "<ObjCObjectPointerTypeLoc>"
  | PackExpansionTypeLoc -> Format.pp_print_string fmt "<PackExpansionTypeLoc>"
  | RValueReferenceTypeLoc -> Format.pp_print_string fmt "<RValueReferenceTypeLoc>"
  | SubstTemplateTypeParmTypeLoc -> Format.pp_print_string fmt "<SubstTemplateTypeParmTypeLoc>"
  | SubstTemplateTypeParmPackTypeLoc -> Format.pp_print_string fmt "<SubstTemplateTypeParmPackTypeLoc>"
  | TemplateSpecializationTypeLoc -> Format.pp_print_string fmt "<TemplateSpecializationTypeLoc>"
  | TemplateTypeParmTypeLoc _ -> Format.pp_print_string fmt "<TemplateTypeParmTypeLoc>"
  | UnaryTransformTypeLoc -> Format.pp_print_string fmt "<UnaryTransformTypeLoc>"
  | UnresolvedUsingTypeLoc -> Format.pp_print_string fmt "<UnresolvedUsingTypeLoc>"
  | VectorTypeLoc -> Format.pp_print_string fmt "<VectorTypeLoc>"

and pp_tloc fmt tloc =
  pp_tloc_ fmt tloc.tl


and pp_type_ fmt = function
  | BuiltinType bt ->
      Format.fprintf fmt "%s"
        (string_of_builtin_type bt)
  | TypedefType name ->
      Format.fprintf fmt "%s"
        name
  | TypeOfExprType expr ->
      Format.fprintf fmt "typeof (%a)"
        pp_expr expr
  | TypeOfType ty ->
      Format.fprintf fmt "typeof (%a)"
        pp_type ty
  | DecltypeType expr ->
      Format.fprintf fmt "decltype (%a)"
        pp_expr expr
  | ParenType ty ->
      Format.fprintf fmt "(%a)"
        pp_type ty
  | PointerType ty ->
      Format.fprintf fmt "%a ptr"
        pp_type ty
  | FunctionNoProtoType ty ->
      Format.fprintf fmt "? -> %a"
        pp_type ty
  | FunctionProtoType (ty, args) ->
      Format.fprintf fmt "(%a) -> %a"
        (Formatx.pp_list pp_type) args
        pp_type ty
  | ConstantArrayType (ty, size) ->
      Format.fprintf fmt "%a[%d]"
        pp_type ty
        size
  | VariableArrayType (ty, size) ->
      Format.fprintf fmt "%a[%a]"
        pp_type ty
        pp_expr size
  | IncompleteArrayType ty ->
      Format.fprintf fmt "%a[]"
        pp_type ty
  | ElaboratedType ty ->
      Format.fprintf fmt "%a"
        pp_type ty
  | RecordType (kind, name) ->
      Format.fprintf fmt "<%s> %s"
        (string_of_tag_type_kind kind)
        (if name = "" then "<anonymous>" else name)
  | EnumType name ->
      Format.pp_print_string fmt
        (if name = "" then "enum <anonymous>" else "enum " ^ name)
  | DecayedType (decayed, original) ->
      Format.fprintf fmt "%a"
        pp_type decayed

  | AtomicType -> Format.pp_print_string fmt "<AtomicType>"
  | AttributedType -> Format.pp_print_string fmt "<AttributedType>"
  | AutoType -> Format.pp_print_string fmt "<AutoType>"
  | BlockPointerType -> Format.pp_print_string fmt "<BlockPointerType>"
  | ComplexType -> Format.pp_print_string fmt "<ComplexType>"
  | DependentNameType -> Format.pp_print_string fmt "<DependentNameType>"
  | DependentSizedArrayType -> Format.pp_print_string fmt "<DependentSizedArrayType>"
  | DependentSizedExtVectorType -> Format.pp_print_string fmt "<DependentSizedExtVectorType>"
  | DependentTemplateSpecializationType -> Format.pp_print_string fmt "<DependentTemplateSpecializationType>"
  | ExtVectorType -> Format.pp_print_string fmt "<ExtVectorType>"
  | InjectedClassNameType -> Format.pp_print_string fmt "<InjectedClassNameType>"
  | LValueReferenceType -> Format.pp_print_string fmt "<LValueReferenceType>"
  | MemberPointerType -> Format.pp_print_string fmt "<MemberPointerType>"
  | ObjCInterfaceType -> Format.pp_print_string fmt "<ObjCInterfaceType>"
  | ObjCObjectPointerType -> Format.pp_print_string fmt "<ObjCObjectPointerType>"
  | ObjCObjectType -> Format.pp_print_string fmt "<ObjCObjectType>"
  | PackExpansionType -> Format.pp_print_string fmt "<PackExpansionType>"
  | RValueReferenceType -> Format.pp_print_string fmt "<RValueReferenceType>"
  | SubstTemplateTypeParmPackType -> Format.pp_print_string fmt "<SubstTemplateTypeParmPackType>"
  | SubstTemplateTypeParmType -> Format.pp_print_string fmt "<SubstTemplateTypeParmType>"
  | TemplateSpecializationType -> Format.pp_print_string fmt "<TemplateSpecializationType>"
  | TemplateTypeParmType _ -> Format.pp_print_string fmt "<TemplateTypeParmType>"
  | UnaryTransformType -> Format.pp_print_string fmt "<UnaryTransformType>"
  | UnresolvedUsingType -> Format.pp_print_string fmt "<UnresolvedUsingType>"
  | VectorType -> Format.pp_print_string fmt "<VectorType>"

and pp_type fmt t =
  Format.fprintf fmt "%a %a%s"
    pp_type_ t.t
    Formatx.(pp_list ~sep:(pp_sep "") pp_print_string)
      (List.map string_of_qualifier t.t_qual)
    (match t.t_aspace with
     | None -> ""
     | Some aspace -> " addr_space_" ^ string_of_int aspace)


and pp_cxx_base_specifier fmt base =
  if base.cbs_virtual then
    Format.pp_print_string fmt "virtual ";
  Format.pp_print_string fmt (string_of_access_specifier base.cbs_access_spec);
  Format.pp_print_string fmt " ";
  pp_tloc fmt base.cbs_type;


and pp_bases fmt = function
  | [] -> ()
  | bases ->
      Formatx.pp_print_string fmt " : ";
      Formatx.pp_list pp_cxx_base_specifier fmt bases


and string_of_declaration_name = function
  | DN_Identifier id -> id
  | DN_ObjCZeroArgSelector -> "<ObjCZeroArgSelector>"
  | DN_ObjCOneArgSelector -> "<ObjCOneArgSelector>"
  | DN_ObjCMultiArgSelector -> "<ObjCMultiArgSelector>"
  | DN_CXXConstructorName ty ->
      pp_type Format.str_formatter ty;
      Format.flush_str_formatter ()
  | DN_CXXDestructorName ty ->
      pp_type Format.str_formatter ty;
      "~" ^ Format.flush_str_formatter ()
  | DN_CXXConversionFunctionName -> "<CXXConversionFunctionName>"
  | DN_CXXOperatorName kind -> "operator" ^ string_of_overloaded_operator_kind kind
  | DN_CXXLiteralOperatorName -> "<CXXLiteralOperatorName>"
  | DN_CXXUsingDirective -> "<CXXUsingDirective>"


and pp_decl_ fmt = function
  | EmptyDecl ->
      Format.pp_print_string fmt ";@,"
  | TranslationUnitDecl decls ->
      Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_decl fmt decls
  | TypedefDecl (ty, name) ->
      Format.fprintf fmt "typedef %s : %a;@,"
        name
        pp_tloc ty
  | FunctionDecl (fd_type, fd_name, fd_body) ->
      Format.fprintf fmt "@[<v2>%a@]%a"
        pp_named_arg (string_of_declaration_name fd_name, fd_type)
        (pp_option pp_stmt) fd_body
  | VarDecl (ty, name, Some init) ->
      Format.fprintf fmt "%a = %a"
        pp_named_arg (name, ty)
        pp_expr init
  | VarDecl (ty, name, None)
  | ParmVarDecl (ty, name) ->
      pp_named_arg fmt (name, ty)
  | RecordDecl (kind, name, None, bases) ->
      Format.fprintf fmt "%s %s@;@,"
        (string_of_tag_type_kind kind)
        (if name = "" then "<anonymous>" else name)
  | RecordDecl (kind, name, Some members, bases) ->
      Format.fprintf fmt "%s %s%a@\n@[<v2>{@,%a@]@\n};@\n"
        (string_of_tag_type_kind kind)
        (if name = "" then "<anonymous>" else name)
        pp_bases bases
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_decl) members
  | FieldDecl { fd_type = ty;
                fd_name = name;
                fd_bitw = bitwidth;
                fd_init = init;
                fd_mutable = is_mutable;
              } ->
      Format.fprintf fmt "%s%a;@,"
        (if is_mutable then "mutable " else "")
        pp_named_arg (name, ty)
  | EnumDecl (name, enumerators) ->
      Format.fprintf fmt "enum %s { %a };@,"
        name
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_decl) enumerators
  | EnumConstantDecl (name, None) ->
      Format.fprintf fmt "%s;@,"
        name
  | EnumConstantDecl (name, Some init) ->
      Format.fprintf fmt "%s = %a;@,"
        name
        pp_expr init
  | NamespaceDecl (name, is_inline, decls) ->
      Format.fprintf fmt "%snamespace %s { %a }"
        (if is_inline then "inline " else "")
        name
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_decl) decls
  | LinkageSpecDecl (decls, lang) ->
      Format.fprintf fmt "extern \"%s\" { %a }"
        (string_of_language lang)
        (Formatx.pp_list ~sep:(Formatx.pp_sep "") pp_decl) decls
  | UsingDecl (name) ->
      Format.fprintf fmt "using %s;@,"
        (string_of_declaration_name name)
  | AccessSpecDecl spec ->
      Format.fprintf fmt "%s:"
        (string_of_access_specifier spec)

  | BlockDecl -> Format.pp_print_string fmt "<BlockDecl>"
  | CapturedDecl -> Format.pp_print_string fmt "<CapturedDecl>"
  | ClassScopeFunctionSpecializationDecl -> Format.pp_print_string fmt "<ClassScopeFunctionSpecializationDecl>"
  | ClassTemplateDecl _ -> Format.pp_print_string fmt "<ClassTemplateDecl>"
  | FileScopeAsmDecl -> Format.pp_print_string fmt "<FileScopeAsmDecl>"
  | FriendDecl -> Format.pp_print_string fmt "<FriendDecl>"
  | FriendTemplateDecl -> Format.pp_print_string fmt "<FriendTemplateDecl>"
  | FunctionTemplateDecl -> Format.pp_print_string fmt "<FunctionTemplateDecl>"
  | ImportDecl -> Format.pp_print_string fmt "<ImportDecl>"
  | IndirectFieldDecl -> Format.pp_print_string fmt "<IndirectFieldDecl>"
  | LabelDecl -> Format.pp_print_string fmt "<LabelDecl>"
  | MSPropertyDecl -> Format.pp_print_string fmt "<MSPropertyDecl>"
  | NamespaceAliasDecl -> Format.pp_print_string fmt "<NamespaceAliasDecl>"
  | NonTypeTemplateParmDecl -> Format.pp_print_string fmt "<NonTypeTemplateParmDecl>"
  | ObjCCategoryDecl -> Format.pp_print_string fmt "<ObjCCategoryDecl>"
  | ObjCCategoryImplDecl -> Format.pp_print_string fmt "<ObjCCategoryImplDecl>"
  | ObjCCompatibleAliasDecl -> Format.pp_print_string fmt "<ObjCCompatibleAliasDecl>"
  | ObjCImplementationDecl -> Format.pp_print_string fmt "<ObjCImplementationDecl>"
  | ObjCInterfaceDecl -> Format.pp_print_string fmt "<ObjCInterfaceDecl>"
  | ObjCMethodDecl -> Format.pp_print_string fmt "<ObjCMethodDecl>"
  | ObjCPropertyDecl -> Format.pp_print_string fmt "<ObjCPropertyDecl>"
  | ObjCPropertyImplDecl -> Format.pp_print_string fmt "<ObjCPropertyImplDecl>"
  | ObjCProtocolDecl -> Format.pp_print_string fmt "<ObjCProtocolDecl>"
  | OMPThreadPrivateDecl -> Format.pp_print_string fmt "<OMPThreadPrivateDecl>"
  | StaticAssertDecl -> Format.pp_print_string fmt "<StaticAssertDecl>"
  | TemplateTemplateParmDecl -> Format.pp_print_string fmt "<TemplateTemplateParmDecl>"
  | TemplateTypeParmDecl _ -> Format.pp_print_string fmt "<TemplateTypeParmDecl>"
  | TypeAliasDecl -> Format.pp_print_string fmt "<TypeAliasDecl>"
  | TypeAliasTemplateDecl -> Format.pp_print_string fmt "<TypeAliasTemplateDecl>"
  | UnresolvedUsingTypenameDecl -> Format.pp_print_string fmt "<UnresolvedUsingTypenameDecl>"
  | UnresolvedUsingValueDecl -> Format.pp_print_string fmt "<UnresolvedUsingValueDecl>"
  | UsingDirectiveDecl -> Format.pp_print_string fmt "<UsingDirectiveDecl>"
  | UsingShadowDecl -> Format.pp_print_string fmt "<UsingShadowDecl>"
  | VarTemplateDecl -> Format.pp_print_string fmt "<VarTemplateDecl>"
  | ClassTemplateSpecializationDecl -> Format.pp_print_string fmt "<ClassTemplateSpecializationDecl>"
  | ClassTemplatePartialSpecializationDecl -> Format.pp_print_string fmt "<ClassTemplatePartialSpecializationDecl>"
  | ObjCAtDefsFieldDecl -> Format.pp_print_string fmt "<ObjCAtDefsFieldDecl>"
  | ObjCIvarDecl -> Format.pp_print_string fmt "<ObjCIvarDecl>"
  | CXXConstructorDecl -> Format.pp_print_string fmt "<CXXConstructorDecl>"
  | CXXConversionDecl -> Format.pp_print_string fmt "<CXXConversionDecl>"
  | CXXDestructorDecl -> Format.pp_print_string fmt "<CXXDestructorDecl>"
  | ImplicitParamDecl -> Format.pp_print_string fmt "<ImplicitParamDecl>"
  | VarTemplateSpecializationDecl -> Format.pp_print_string fmt "<VarTemplateSpecializationDecl>"
  | VarTemplatePartialSpecializationDecl -> Format.pp_print_string fmt "<VarTemplatePartialSpecializationDecl>"

and pp_decl fmt decl =
  pp_decl_ fmt decl.d


and pp_named_arg fmt = function
  | ("", ty) ->
      pp_tloc fmt ty
  | (name, ty) ->
      Format.fprintf fmt "%s : %a"
        name
        pp_tloc ty
