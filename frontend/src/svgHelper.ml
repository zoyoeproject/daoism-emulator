let mk_group name inner_html =
  Printf.sprintf "<g id='%s'>%s</g>" name inner_html

let mk_text style center txt =
  Printf.sprintf "<text x='%d' y='%d' class='%s'>%s</text>" (fst center) (snd center) style txt

let mk_rectangle style (w,h) (cx, cy) =
  let points = Printf.sprintf
    "%d,%d %d,%d %d,%d %d,%d %d,%d"
    cx cy (cx+w) cy (cx+w) (cy+h) cx (cy+h) cx cy
  in
  Printf.sprintf "<polygon class='%s' points='%s'></polygon>" style points

let mk_hexagon name r (cx, cy) =
  let points = ((cx-30, cy), (cx-15, cy-26), (cx+15, cy-26),
    (cx+30, cy), (cx+15, cy+26), (cx-15, cy+26))
  in
  let (x0,y0), (x1,y1), (x2,y2), (x3,y3), (x4,y4), (x5, y5) = points in
  let points:string = Printf.sprintf
    "%d,%d %d,%d %d,%d %d,%d %d,%d %d,%d %d,%d"
    x0 y0 x1 y1 x2 y2 x3 y3 x4 y4 x5 y5 x0 y0
  in
  Printf.sprintf "<polygon id='%s' class='%s' points='%s'></polygon>"
    name r points

let mk_line (x1,y1) (x2,y2) =
  Printf.sprintf "<line x1='%f' y1='%f' x2='%f' y2='%f' class='river' />"
    x1 y1 x2 y2

let mk_arc_line (x1,y1) (x2,y2) (cx,cy) =
  Printf.sprintf "<path d='M %f %f Q %f %f, %f %f' style='stroke:blue; stroke-width:2'/>"
    x1 y1 cx cy x2 y2

let mk_use svgname (cx, cy) =
  Printf.sprintf "<use href='/dist/res/%s.svg#main' x='%d' y='%d' width='30' height='30'/>" svgname (cx-15) (cy-15)

let mk_internal_use svgname (cx, cy) =
  Printf.sprintf "<use href='#%s' x='%d' y='%d' width='30' height='30'/>" svgname (cx-15) (cy-15)


(* Make dynamic elements with event listeners *)
let mk_button_in container name (w, h) (cx, cy) txt cb =
  let item = Document.createElementSVG Document.document "g" in
  let points = Printf.sprintf
    "%d,%d %d,%d %d,%d %d,%d %d,%d"
    cx cy (cx+w) cy (cx+w) (cy+h) cx (cy+h) cx cy
  in
  let rect = Printf.sprintf "<polygon class='menu-button' points='%s'></polygon>"
    points in
  let txt = mk_text "button-text" (cx+5, (cy+5+h/2)) txt in
  Document.setAttribute item "id" name;
  Document.setInnerHTML item (rect ^ txt);
  Document.appendChild container item;
  Document.add_event_listener item "click" cb

let mk_rectangle_in container (w,h) (cx, cy) =
  let points = Printf.sprintf
    "%d,%d %d,%d %d,%d %d,%d %d,%d"
    cx cy (cx+w) cy (cx+w) (cy+h) cx (cy+h) cx cy
  in
  let item = Document.createElementSVG Document.document "polygon" in
  item |. Document.setAttribute "class" "menu";
  item |. Document.setAttribute "points" points;
  Document.appendChild container item
