let rec (concat : ['a*] -> ['b*] -> ['a* ; 'b*]) x y =
  match x with
  | [] -> y
  | (h, t) -> (h, concat t y)
  end

let rec flatten x = match x with
 | [] -> []
 | (h, t) & :List -> concat (flatten h) (flatten t)
 | _ -> [x]
end

