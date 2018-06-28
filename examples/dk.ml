
type env_tuple = {
  ctx : int;
  term : int;
  stack : int;
  reduc : (bool * env_tuple) ref;
}

type env_fields = {
  ctx : int;
  term : int;
  stack : int;
  mutable reduc_bool : bool;
  mutable reduc_state : env_fields;
}

let rec env_tuple = {
  ctx = 0; term = 1; stack = 2;
  reduc = { contents = (true, env_tuple); };
}

let rec env_fields = {
  ctx = 0; term = 1; stack = 2;
  reduc_bool = true;
  reduc_state = env_fields;
}

let () =
  Repr.(context (fun ctx ->
      Dot.print_list Format.std_formatter [
        "env_tuple", ctx.mk env_tuple;
        "env_fields", ctx.mk env_fields;
      ]))
