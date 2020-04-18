module type Interface = sig

  module ID: UID.Interface
  module Env: Environ.Interface

  type t = <
    get_name: string;
    take_features: Env.Feature.t list -> unit;
    step: unit -> (Env.Feature.t * t ref) list
  >

  class virtual elt: string -> object
    val name: string
    val uid: ID.t
    val mutable env: Env.t
    val mutable modifier: Env.Modifier.t list
    method get_name: string
    method take_features: Env.Feature.t list -> unit
    method virtual step: unit -> (Env.Feature.t * t ref) list
  end


  type ('a, 'b) state_trans =
    'a -> 'b * (Env.Feature.t * (t ref option)) list * Timer.time_slice

end

module Make (ID:UID.Interface) (Env: Environ.Interface) = struct

  module Env = Env
  module ID = ID

  type t = <
    get_name: string;
    take_features: Env.Feature.t list -> unit;
    step: unit -> (Env.Feature.t * t ref) list
  >

  type ('a, 'b) state_trans =
    'a -> 'b * (Env.Feature.t * (t ref option)) list * Timer.time_slice

  class virtual elt n = object

    val name = n
    val uid = ID.of_string n
    val mutable env = Env.empty
    val mutable modifier: Env.Modifier.t list = []

    method get_name = name

    method take_features features =
      env <- List.fold_left (fun acc f ->
         Env.proceed_feature f acc
      ) env features

    method virtual step: unit -> (Env.Feature.t * t ref) list
  end
end


