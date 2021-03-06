
let size=65536 (* 64k. no particular reason *)

let parse text =
  let lexbuf = Lexing.from_string text in
  Lvmconfigparser.start Lvmconfiglex.lvmtok lexbuf

let to_text vg =
  let b = Buffer.create size in
  let bp = Printf.bprintf in
  bp b "%s {\nid = \"%s\"\nseqno = %d\nstatus = [%s]\nextent_size = %Ld\nmax_lv = %d\nmax_pv = %d\n\n"
    vg.Lvmty.VG.name vg.Lvmty.VG.id vg.Lvmty.VG.seqno
    (String.concat ", " (List.map (fun x -> Printf.sprintf "\"%s\"" (Lvmty.VG.status_to_string x)) vg.Lvmty.VG.status))
    vg.Lvmty.VG.extent_size vg.Lvmty.VG.max_lv vg.Lvmty.VG.max_pv;

  let write_pv pv =
    bp b "\n%s {\nid = \"%s\"\ndevice = \"%s\"\n\nstatus = [%s]\ndev_size = %Ld\npe_start = %Ld\npe_count = %Ld\n}\n" pv.Lvmty.PV.name pv.Lvmty.PV.id pv.Lvmty.PV.dev 
      (String.concat ", " (List.map (fun x -> Printf.sprintf "\"%s\"" (Lvmty.PV.status_to_string x)) pv.Lvmty.PV.status))
      pv.Lvmty.PV.dev_size pv.Lvmty.PV.pe_start pv.Lvmty.PV.pe_count
  in

  bp b "physical_volumes {\n";
  List.iter write_pv vg.Lvmty.VG.pvs;
  bp b "}\n\n";

  let write_lv lv =
    bp b "\n%s {\nid = \"%s\"\nstatus = [%s]\n" lv.Lvmty.LV.name lv.Lvmty.LV.id 
      (String.concat ", " (List.map (fun x -> Printf.sprintf "\"%s\"" (Lvmty.LV.status_to_string x)) lv.Lvmty.LV.status));
    if List.length lv.Lvmty.LV.tags > 0 then 
      bp b "tags = [%s]\n" (String.concat ", " (List.map (fun s -> Printf.sprintf "\"%s\"" s) lv.Lvmty.LV.tags));
    bp b "segment_count = %d\n\n" (Array.length lv.Lvmty.LV.segments);
    Array.iteri (fun i s -> 
      let stripes = Array.length s.Lvmty.LV.stripes in
      bp b "segment%d {\nstart_extent = %Ld\nextent_count = %Ld\n\ntype = \"striped\"\nstripe_count = %d%s\n\nstripes = [\n" (i+1) s.Lvmty.LV.start_extent s.Lvmty.LV.extent_count
	stripes (if stripes=1 then "\t# linear" else "");
      Array.iter (fun (pv,offset) -> bp b "\"%s\", %Ld\n" pv offset) s.Lvmty.LV.stripes;
      bp b "]\n}\n") lv.Lvmty.LV.segments;
    bp b "}\n"
  in

  bp b "logical_volumes {\n";
  List.iter write_lv vg.Lvmty.VG.lvs;
  bp b "}\n}\n";

  bp b "# Generated by MLVM version 0.1: \n\n";
  bp b "contents = \"Text Format Volume Group\"\n";
  bp b "version = 1\n\n";
  bp b "description = \"\"\n\n";
  bp b "creation_host = \"%s\"\n" "<need uname!>";
  bp b "creation_time = %Ld\n\n" (Int64.of_float (Unix.time ()));
  Buffer.contents b

  
      
      
	


    
  
