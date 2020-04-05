module type Event = sig

  type ('a, 'b) t

  val get_source: ('a, 'b) t -> 'a
  val get_feature: ('a, 'b) t -> 'b
  val to_string: ('a, 'b) t -> string

end

module Make (O:Object.Interface) (F:Feature.Interface) = struct

  type t = (O.t ref) * (F.t)

  let get_source t = !(fst t)

  let get_feature t = snd t

  let to_string t =
    Printf.sprintf "<source: %s, feature: %s>"
      (O.to_string (get_source t)) (F.to_string (get_feature t))

end
