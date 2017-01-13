(* TODO: move parts depending on x86 architecture (eax for instance in result) into a subdirectory x86 *)
module Make(D: Domain.T) =
struct
  type fun_type = {
        name: string;
        libname: string;
        prologue: Asm.stmt list;
        stub: Asm.stmt list;
        epilogue: Asm.stmt list
  }

  let tbl: (Data.Address.t, fun_type) Hashtbl.t = Hashtbl.create 5
      
  exception Found of (Data.Address.t * fun_type)
  let search_by_name (fun_name: string): (Data.Address.t * fun_type) =
    try
      Hashtbl.iter (fun a fundec ->
	if String.compare fundec.name fun_name = 0 then
	  raise (Found (a, fundec))
	else ()
      ) tbl;
      raise Not_found
    with Found pair -> pair 

  open Asm

  (* x86 depend *)
  let esp () = Register.of_name "esp"

  (* x86 dependent *)
  let arg n =
    let esp = Register.of_name "esp" in
    Lval (M (BinOp (Add, Lval (V (T (esp))), Const (Data.Word.of_int (Z.of_int n) !Config.stack_width)), !Config.stack_width))

  (* x86 dependent *)
  let sprintf_stdcall () =
    let buf = arg 4 in
    let format = arg 8 in
    let va_arg = arg 12 in
    let res = Register.of_name "eax" in
    [ Directive (Stub ("sprintf",  [Lval (V (T res)) ; buf ; format ; va_arg])) ]

  let sprintf_cdecl = sprintf_stdcall

  let strlen_stdcall () =
    let buf = arg 4 in
    let res = Register.of_name "eax" in
    [ Directive (Stub ("strlen",  [Lval (V (T res)) ; buf])) ]

  let strlen_cdecl = strlen_stdcall

  let memcpy_stdcall () =
    let dst = arg 4 in
    let src = arg 8 in
    let sz = arg 12 in
    let res = Register.of_name "eax" in
    [ Directive (Stub ("sprintf",  [Lval (V (T res)) ; dst ; src ; sz])) ]

  let memcpy_cdecl = memcpy_stdcall
    
  let stdcall_stubs: (string, stmt list) Hashtbl.t = Hashtbl.create 5;;
  let cdecl_stubs: (string, stmt list) Hashtbl.t = Hashtbl.create 5;;

  let init () =
    Hashtbl.add stdcall_stubs "memcpy" (sprintf_stdcall ());
    Hashtbl.add cdecl_stubs "memcpy" (sprintf_cdecl ());
    Hashtbl.add stdcall_stubs "sprintf" (sprintf_stdcall ());
    Hashtbl.add cdecl_stubs "sprintf" (sprintf_cdecl ());
    Hashtbl.add stdcall_stubs "strlen" (strlen_stdcall ());
    Hashtbl.add cdecl_stubs "strlen" (strlen_cdecl ());;
  
end
