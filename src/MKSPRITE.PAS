program Sprite_Maker;
{
Auteur: Patrick Pr‚martin.
Date: 11/08/1992. 12/08/1992. 14/08/1992. 18/10/1992.
Langage: Turbo Pascal 6.0
But: Cr‚ation des fichiers d'extension .SPR contenant des sprites (avec
     ‚ventuelles animations).
}

uses
    olf_software,
    crt,
    u_spr,
    u_sgf,
    u_pal,
    u_icn,
    u_msg,
    u_mou,
    u_m_zone,
    u_m_util,
    u_int10h,
    u_vga_graph,
    u_code_clavier;

const
     num_ver = '1.1';
     dat_ver = '10/18/1992';
     mou_cross = 1;

type
    t_tab_icn = array [1..11] of p_icn;
    p_m_zone2 = ^o_m_zone2;
    o_m_zone2 =
      object (o_m_zone)
        ox,
        oy : byte;
        procedure idle; virtual;
      end;
    p_m_zone3 = ^o_m_zone3;
    o_m_zone3 =
      object (o_m_zone)
        sens : t_sens_fleche;
        num : word;
        procedure idle; virtual;
      end;
    t_sprite = array [0..63, 0..63] of byte;
    t_tab_coord = array [1..10] of word;

var
   icn_x,
   icn_y : t_tab_coord;
   coul_fond_spr,
   couleur,
   indice,
   om : byte;
   zone : p_m_zone2;
   icn : t_tab_icn;
   croix : boolean;
   sprite,
   undo,
   tampon : t_sprite;
   nb_spr,
   num_spr : word;
   nom_fich_spr,
   nom_fich_pal : string;

procedure get_sprite (n : word);
var
   i, j, l, h : word;
   p : pointer;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
      sprite [i, j] := 0;
    {endfor}
  {endfor}
  if (liste_sprite^.tst_num (n))
  then
    begin
      liste_sprite^.get_taille (n, l, h);
      p := liste_sprite^.get_forme (n);
      {$r-}
      for j := 0 to pred (h) do
        for i := 0 to pred (l) do
          sprite [i, j] := mem [seg (p^):ofs (p^)+i+j*l];
        {endfor}
      {endfor}
      {$r+}
    end;
  {endif}
  for i := 0 to 63 do
    for j := 0 to 63 do
      undo [i, j] := sprite [i, j];
    {endfor}
  {endfor}
end; { get_sprite }

procedure set_sprite (n : word);
var
   s : p_spr;
   e : p_spr_lst;
   i, j : byte;
begin
  if (liste_sprite <> nil)
  then
    s := liste_sprite^.get_sprite (n)
  else
    s := nil;
  {endif}
  if (s = nil)
  then
    begin
      s := new (p_spr, init);
      if (s <> nil)
      then
        s^.numero := n;
      {endif}
    end;
  {endif}
  if (s <> nil)
  then
    begin
      if (s^.forme <> nil)
      then
        freemem (s^.forme, s^.largeur*s^.hauteur);
      {endif}
    { D‚termination de la largeur du sprite. }
      s^.largeur := 0;
      i := 63;
      while ((i > 0) and (s^.largeur = 0)) do
        begin
          for j := 0 to 63 do
            if (sprite [i, j] <> 0)
            then
              s^.largeur := succ (i);
            {endif}
          {endfor}
          dec (i);
        end;
      {endwhile}
      if (s^.largeur = 0)
      then
        s^.largeur := succ (j);
      {endif}
    { D‚termination de la hauteur du sprite. }
      s^.hauteur := 0;
      j := 63;
      while ((j > 0) and (s^.hauteur = 0)) do
        begin
          for i := 0 to 63 do
            if (sprite [i, j] <> 0)
            then
              s^.hauteur := succ (j);
            {endif}
          {endfor}
          dec (j);
        end;
      {endwhile}
      if (s^.hauteur = 0)
      then
        s^.hauteur := succ (j);
      {endif}
    { Initialisation de la forme du sprite. }
      getmem (s^.forme, s^.largeur*s^.hauteur);
      if (s^.forme <> nil)
      then
        for i := 0 to pred (s^.largeur) do
          for j := 0 to pred (s^.hauteur) do
            mem [seg(s^.forme^):ofs(s^.forme^)+i+j*s^.largeur] := sprite [i, j];
          {endfor}
        {endfor}
      {endif}
    { Mise … jour de la liste des sprites. }
      if (liste_sprite = nil)
      then
        begin
          liste_sprite := new (p_spr_lst, init (s));
          inc (nb_max_sprite);
        end
      else
        begin
          if (not (liste_sprite^.tst_num (n)))
          then
            begin
              e := liste_sprite;
              while (e^.next <> nil) do
                e := e^.next;
              {endwhile}
              e^.next := new (p_spr_lst, init (s));
              inc (nb_max_sprite);
            end;
          {endif}
        end;
      {endif}
    end;
  {endif}
end; { set_sprite }

procedure forme_souris (n : word);
begin
  if (mou_select (n) <> 0)
  then
    begin
      writeln (get_msg (5));
      halt (1);
    end;
  {endif}
end; { forme_souris }

procedure get_coord_xy (var i, j : byte);
var
   mx,
   my : integer;
begin
  mx := pos_m_x div 2;
  my := pos_m_y;
  if ((mx < 0) or (my < 0) or (mx > 191) or (my > 191))
  then
    begin
      i := 64;
      j := 64;
    end
  else
    begin
      i := mx div 3;
      j := my div 3;
    end;
  {endif}
end; { get_coord_xy }

procedure dessin_loupe (i, j : byte);
var
   k,
   l : integer;
   c : byte;
begin
  if ((i > 63) or (j > 63))
  then
    begin
      box (243, 155, 292, 188, darkgray);
      box (244, 156, 291, 187, lightgray);
      box (245, 157, 290, 186, white);
      box (246, 158, 289, 185, lightgray);
      box (247, 159, 288, 184, darkgray);
      boxf (248, 160, 287, 183, black);
    end
  else
    for k := i-2 to i+2 do
      for l := j-1 to j+1 do
        begin
          if ((k < 0) or (l < 0) or (k > 63) or (l > 63))
          then
            c := 1
          else
            c := sprite [k, l];
          {endif}
          if (c = 0)
          then
            begin
              box (248+(k+2-i)*8,160+(l+1-j)*8, 248+(k+2-i)*8+6,160+(l+1-j)*8+6,white);
              box (248+1+(k+2-i)*8,160+1+(l+1-j)*8, 248+(k+2-i)*8+5,160+(l+1-j)*8+5,lightgray);
              box (248+2+(k+2-i)*8,160+2+(l+1-j)*8, 248+(k+2-i)*8+4,160+(l+1-j)*8+4,darkgray);
            end
          else
            begin
              if (c = 1)
              then
                c := 0;
              {endif}
              boxf (248+(k+2-i)*8,160+(l+1-j)*8, 248+(k+2-i)*8+6,160+(l+1-j)*8+6,c);
            end;
          {endif}
          line (264, 168, 271, 175, white);
          line (264, 175, 271, 168, black);
        end;
      {endfor}
    {endfor}
  {endif}
end; { dessin_loupe }

function valide_sprite : boolean;
var
   i, j : byte;
   b : boolean;
begin
  b := false;
  i := 0;
  while ((i < 64) and (not b)) do
    begin
      j := 0;
      while ((j < 64) and (not b)) do
        begin
          b := b or (sprite [i, j] <> 0);
          inc (j);
        end;
      {endwhile}
      inc (i);
    end;
  {endwhile}
  valide_sprite := b;
end; { valide_sprite }

procedure o_m_zone2.idle;
var
   i, j : byte;
begin
  get_coord_xy (i, j);
  if ((i < 64) and (j < 64))
  then
    begin
      if not croix
      then
        begin
          forme_souris (mou_cross);
          croix := true;
          dessin_loupe (i, j);
        end
      else
        if ((ox <> i) or (oy <> j) or (pos_m_k <> 0))
        then
          dessin_loupe (i, j);
        {endif}
      {endif}
      ox := i;
      oy := j;
    end
  else
    begin
      if croix
      then
        begin
          forme_souris (0);
          croix := false;
          dessin_loupe (64, 64);
        end;
      {endif}
    end;
  {endif}
end; { o_m_zone2.idle }

procedure o_m_zone3.idle;
var
   i,
   j : byte;
begin
  repeat
    get_sprite (num);
    case sens of
      gauche :
        if (num > 0)
        then
          dec (num)
        else
          num := nb_spr;
        {endif}
      droite :
        if (num < nb_spr)
        then
          inc (num)
        else
          num := 0;
        {endif}
    end;
  until (valide_sprite);
  for i := 0 to 63 do
    for j := 0 to 63 do
      pset (10*8+i, 4*8+j, sprite [i, j]);
    {endfor}
  {endfor}
end; { o_m_zone3.idle }

procedure init;
var
   i,
   j : byte;
   ch : string;
begin
  write (get_msg (6));
  nom_fich_pal := 'STANDARD.PAL';
  nom_fich_spr := '';
  croix := false;
  if (mou_register (mou_load (get_file_name ('CROSS.MOU')), mou_cross) <> 0)
  then
    begin
      writeln (get_msg (3));
      halt (1);
    end;
  {endif}
  for i := 1 to 11 do
    begin
      case i of
        1 : ch := 'HELP';
        2 : ch := 'SAVE';
        3 : ch := 'LOAD';
        4 : ch := 'LOAD_PAL';
        5 : ch := 'CAMERA';
        6 : ch := 'PUSH';
        7 : ch := 'POP';
        8 : ch := 'UNDO';
        9 : ch := '';
        10 : ch := 'EXIT_DOS';
        11 : ch := 'OK';
      end;
      if (ch = '')
      then
        icn [i] := nil
      else
        if (i = 11)
        then
          icn [i] := new (p_icn, load (get_file_name (ch+'.ICN'), red, green,
                                       lightgreen))
        else
          icn [i] := new (p_icn, load (get_file_name (ch+'.ICN'), black,
                                       darkgray, lightgray));
        {endif}
      {endif}
    end;
  {endfor}
  zone := new (p_m_zone2, init);
  if (zone = nil)
  then
    begin
      writeln (get_msg (4));
      halt (1);
    end;
  {endif}
  zone^.ox := 0;
  zone^.oy := 0;
  for i := 0 to 63 do
    for j := 0 to 63 do
      begin
        sprite [i, j] := 0;
        tampon [i, j] := 0
      end;
    {endfor}
  {endfor}
  num_spr := 0;
  nb_spr := 0;
  couleur := 16;
  indice := 0;
end; { init}

procedure done;
var
   i : byte;
begin
  for i := 1 to 10 do
    if (icn [i] <> nil)
    then
      dispose (icn [i], done);
    {endif}
  {endfor}
  if (zone <> nil)
  then
    dispose (zone, done);
  {endif}
end; { done }

procedure dessin_couleur;
var
   i : byte;
begin
  for i := 1 to 12 do
    begin
      textattr := pred (couleur+i);
      gotoxy (26, 11+i);
      write (#219#219);
    end;
  {endfor}
  textattr := coul_fond_spr;
  gotoxy (26, 11);
  write (#176#176);
  line (25*8, 10*8+indice*8, 25*8+15, 10*8+7+indice*8, lightgray);
  line (25*8+15, 10*8+indice*8, 25*8, 10*8+7+indice*8, white);
end; { dessin_couleur }

procedure met_point (i, j : byte);
begin
  if (sprite [i, j] = 0)
  then
    begin
      pset (i*3, j*3, black);
      pset (i*3+1, j*3, darkgray);
      pset (i*3+1, j*3+1, lightgray);
      pset (i*3, j*3+1, white);
      pset (232+i, 72+j, coul_fond_spr);
    end
  else
    begin
      boxf (i*3, j*3, i*3+1, j*3+1, sprite [i, j]);
      pset (232+i, 72+j, sprite [i, j]);
    end;
  {endif}
  line (i*3, j*3+2, i*3+2, j*3+2, black);
  line (i*3+2, j*3, i*3+2, j*3+2, black);
  pset (i*3+2, j*3+2, white);
end; { met_point }

procedure dessin_sprite;
var
   i,
   j : byte;
begin
  coul_fond_spr := succ (random (14));
  for i := 0 to 63 do
    for j := 0 to 63 do
      met_point (i, j);
    {endfor}
  {endfor}
  gotoxy (30, 18);
  textattr := white;
  write ('SPR= ', num_spr : 3);
  remplace_couleur ((30-1)*8, (18-1)*8, (30-1)*8+8*8-1, (18-1)*8+7, black, lightgray);
end; { dessin_sprite }

procedure dessin_ecran; { Affichages et initialisation des zones de clicage. }
var
   i,
   x,
   y : byte;
begin
  for x := 0 to 63 do
    for y := 0 to 63 do
      undo [x, y] := 0;
    {endfor}
  {endfor}
  dessin_loupe (64, 64);
  x := 26;
  y := 4;
  for i := 1 to 10 do
    begin
      if (icn [i] <> nil)
      then
        begin
          icn_x [i] := (x-2)*8;
          icn_y [i] := pred (y)*8;
          icn [i]^.aff_sortie (icn_x [i], icn_y [i]);
          zone^.add_zone3 (x, y, 2, 2, true, chr (ord (touche_f1)+pred (i)));
        end;
      {endif}
      inc (x, 3);
      if (x > 40)
      then
        begin
          x := 26;
          inc (y, 3);
        end;
      {endif}
    end;
  {endfor}
  gotoxy (27, 1);
  textattr := lightgray;
  write ('Sprite Maker');
  gotoxy (27, 2);
  textattr := darkgray;
  write ('(c)PREPAT 92');
  dessin_cadre (26, 1, 38, 3, darkgray, lightgray, black, white);
  zone^.add_zone3 (1, 1, 24, 24, true, #255);
  dessin_couleur;
  dessin_sprite;
  dessin_fleche_zone (26, 10, 2, 1,  lightgray, white, haut, zone, true,
                      touche_page_up);
  dessin_fleche_zone (26, 24, 2, 1,  lightgray, white, bas, zone, true,
                      touche_page_dn);
  dessin_fleche_zone (29, 10, 1, 9,  lightgray, white, gauche, zone, true,
                      touche_gauche);
  dessin_fleche_zone (38, 10, 1, 9,  lightgray, white, droite, zone, true,
                      touche_droite);
  for i := 11 to 23 do
    zone^.add_zone3 (26, i, 2, 1, true, chr (200-11+i));
  {endfor}
end; { dessin_ecran }

procedure sprite2tampon;
var
   i,
   j : byte;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
      tampon [i, j] := sprite [i, j];
    {endfor}
  {endfor}
end; { sprite2tampon }

procedure tampon2sprite;
var
   i,
   j : byte;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
      sprite [i, j] := tampon [i, j];
    {endfor}
  {endfor}
  dessin_sprite;
end; { tampon2sprite }

procedure informations;
var
   zone : p_m_zone;
   code_nul : boolean;
   c : char;

  procedure aff_center (ch : string);
  var
     n : byte;
  begin
    n := 3+((20 - length (ch)) shr 1);
    gotoxy (n, wherey);
    writeln (ch);
  end; { aff_center }

begin
  set_sprite (num_spr);
  textattr := yellow;
  boxf (16, 32, 16+20*8, 32+13*8, black);
  gotoxy (1, 5);
  aff_center ('Sprite Maker');
  aff_center ('(c) P. Premartin');
  aff_center ('(c) Olf Software');
  aff_center ('');
  aff_center ('v.'+num_ver+' d.'+dat_ver);
  aff_center ('');
  aff_center (get_msg (8));
  aff_center ('Premartin Patrick');
  aff_center ('(Olf Software)');
  aff_center ('Lot. Le Souleiado');
  aff_center ('13790 Rousset');
  aff_center ('France');
  dessin_cadre (2, 5, 22, 18, darkgray, lightgray, black, red);
  zone := new (p_m_zone, init);
  if (zone <> nil)
  then
    begin
      icn [11]^.aff_sortie (19*8, 14*8);
      zone^.add_zone3 (21, 15, 2, 2, false, touche_return);
      repeat
        zone^.test_souris (code_nul, c);
      until ((code_nul = false) and (c = touche_return));
      icn [11]^.aff_enfonce (19*8, 14*8);
      dispose (zone, done);
    end;
  {endif}
  dessin_sprite;
end; { informations }

procedure set_point;
var
   i, j, x, y : byte;
begin
  get_coord_xy (i, j);
  if ((i < 64) and (j < 64))
  then
    begin
      for x := 0 to 63 do
        for y := 0 to 63 do
          undo [x, y] := sprite [x, y];
        {endfor}
      {endfor}
      if (indice = 0)
      then
        sprite [i, j] := 0
      else
        sprite [i, j] := pred (indice)+couleur;
      {endif}
      met_point (i, j);
    end;
  {endif}
end; { set_point }

procedure rempli_zone; { Algorithme implantable de remplissage de zones. }
var
   i, j, x, y, nc, os, c : byte;

   procedure recurs (x, y : byte);
   var
      fin : boolean;
      i : byte;
   begin
     if (sprite [x, y] = c)
     then
       begin
         while ((x < 63) and (sprite [succ (x), y] = c)) do
           inc (x);
         {endwhile}
         i := x;
         fin := false;
         os := nc;
         while ((not fin) and (sprite [x, y] = c)) do
           begin
             sprite [x, y] := nc;
             met_point (x, y);
             if (x = 0)
             then
               fin := true
             else
               begin
                 dec (x);
                 os := sprite [x, y];
               end;
             {endif}
           end;
         {endwhile}
         if (os <> c)
         then
           inc (x);
         {endif}
         while ((x <= i) and (sprite [x, y] = nc)) do
           begin
             if ((y > 0) and (sprite [x, y-1] = c))
             then
               recurs (x, pred (y));
             {endif}
             if ((y < 63) and (sprite [x, y+1] = c))
             then
               recurs (x, succ (y));
             {endif}
             inc (x);
           end;
         {endwhile}
       end;
     {endif}
   end; { recurs }

begin
  get_coord_xy (i, j);
  if ((i < 64) and (j < 64))
  then
    begin
      for x := 0 to 63 do
        for y := 0 to 63 do
          undo [x, y] := sprite [x, y];
        {endfor}
      {endfor}
      c := sprite [i, j];
      if (indice = 0)
      then
        nc := 0
      else
        nc := pred (indice)+couleur;
      {endif}
      if (c <> nc)
      then
        recurs (i, j);
      {endif}
    end;
  {endif}
end; { rempli_zone }

procedure change_sprite (n : word);
var
   b : boolean;
begin
  b := valide_sprite;
  if (b or (num_spr < nb_spr) or ((not b) and (n < num_spr)))
  then
    begin
      set_sprite (num_spr);
      if (n > nb_spr)
      then
        begin
          inc (nb_spr);
          n := nb_spr;
        end;
      {endif}
      num_spr := n;
      get_sprite (num_spr);
      dessin_sprite;
    end
  else
    alert (get_msg (13), al_error);
  {endif}
end; { change_sprite }

procedure sauver_spr;
begin
  if confirm (get_msg (9))
  then
    begin
      nom_fich_spr := get_fich_name (nom_fich_spr, 'SPR');
      if ((get_nom_fichier2 (nom_fich_spr) <> '') and ((valide_sprite)
                                                  or (nb_spr > 0)))
      then
        begin
          if ((valide_sprite) or (num_spr < nb_spr))
          then
            set_sprite (num_spr);
          {endif}
          save_sprite_liste (nom_fich_spr);
        end;
      {endif}
    end;
  {endif}
end; { sauver_spr }

procedure charger_spr;
begin
  if confirm (get_msg (10))
  then
    begin
      nom_fich_spr := get_fich_name (nom_fich_spr, 'SPR');
      if (get_nom_fichier2 (nom_fich_spr) <> '')
      then
        begin
          remove_sprite;
          num_spr := register_sprite (nom_fich_spr);
          nb_spr := pred (nb_max_sprite);
          get_sprite (num_spr);
          dessin_sprite;
        end
      else
        begin
          remove_sprite;
          num_spr := 0;
          nb_spr := 0;
          get_sprite (num_spr);
          dessin_sprite;
        end;
      {endif}
    end;
  {endif}
end; {charger_spr }

procedure charger_pal;
var
   p : p_pal;
   i : byte;
begin
  if confirm (get_msg (11))
  then
    begin
      nom_fich_pal := get_fich_name (nom_fich_pal, 'PAL');
      if (get_nom_fichier2 (nom_fich_pal) <> '')
      then
        begin
          p := load_pal (get_file_name (nom_fich_pal));
          if (p <> nil)
          then
            begin
              for i := 16 to 256-16 do
                begin
                  p^ [i-16].r := p^ [i].r;
                  p^ [i-16].v := p^ [i].v;
                  p^ [i-16].b := p^ [i].b;
                end;
              {endfor}
              set_blk_cna_reg (16, 256-16, p^);
              dispose (p);
            end;
          {endif}
        end;
      {endif}
    end;
  {endif}
end; { charger_pal }

procedure run_camera;
var
   zone : p_m_zone3;
   code_nul : boolean;
   c : char;
begin
  zone := new (p_m_zone3, init);
  if (zone <> nil)
  then
    if (nb_spr = 0)
    then
      dispose (zone, done)
    else
      begin
        set_sprite (num_spr);
        zone^.sens := droite;
        zone^.num := 0;
        dessin_fleche_zone (10, 5, 1, 8, darkgray, lightgray, gauche, zone,
                            true, touche_gauche);
        dessin_fleche_zone (19, 5, 1, 8, darkgray, lightgray, droite, zone,
                            true, touche_droite);
        icn [11]^.aff_sortie ((14-2)*8, (14-1)*8);
        zone^.add_zone3 (14, 14, 2, 2, false, touche_return);
        repeat
          zone^.test_souris (code_nul, c);
          if (code_nul = true)
          then
            case c of
              touche_gauche : zone^.sens := gauche;
              touche_droite : zone^.sens := droite;
            end;
          {endif}
        until ((code_nul = false) and ((c = touche_escape) or (c = touche_return)));
        dispose (zone, done);
        icn [11]^.aff_enfonce ((14-2)*8, (14-1)*8);
        get_sprite (num_spr);
        dessin_sprite;
      end;
    {endif}
  {endif}
end; { run_camera }

procedure do_undo;
var
   i, j : byte;
begin
  for i := 0 to 63 do
    for j := 0 to 63 do
      sprite [i, j] := undo [i, j];
    {endfor}
  {endfor}
  dessin_sprite;
end; { do_undo }

procedure scr_haut;
var
   i, j, k : byte;
begin
  for i := 0 to 63 do
    begin
      k := sprite [i, 0];
      for j := 0 to 62 do
        sprite [i, j] := sprite [i, j+1];
      {endfor}
      sprite [i, 63] := k;
    end;
  {endfor}
end; { scr_haut }

procedure scr_bas;
var
   i, j, k : byte;
begin
  for i := 0 to 63 do
    begin
      k := sprite [i, 63];
      for j := 63 downto 1 do
        sprite [i, j] := sprite [i, j-1];
      {endfor}
      sprite [i, 0] := k;
    end;
  {endfor}
end; { scr_bas }

procedure scr_gauche;
var
   i, j, k : byte;
begin
  for j := 0 to 63 do
    begin
      k := sprite [0, j];
      for i := 0 to 62 do
        sprite [i, j] := sprite [i+1, j];
      {endfor}
      sprite [63, j] := k;
    end;
  {endfor}
end; { scr_gauche }

procedure scr_droite;
var
   i, j, k : byte;
begin
  for j := 0 to 63 do
    begin
      k := sprite [63, j];
      for i := 63 downto 1 do
        sprite [i, j] := sprite [i-1, j];
      {endfor}
      sprite [0, j] := k;
    end;
  {endfor}
end; { scr_droite }

procedure scroll_haut_gauche;
begin
  scr_gauche;
  scr_haut;
  dessin_sprite;
end; { scroll_haut_gauche }

procedure scroll_haut;
begin
  scr_haut;
  dessin_sprite;
end; { scroll_haut }

procedure scroll_haut_droite;
begin
  scr_haut;
  scr_droite;
  dessin_sprite;
end; { scroll_haut_droite }

procedure scroll_gauche;
begin
  scr_gauche;
  dessin_sprite;
end; { scroll_gauche }

procedure scroll_droite;
begin
  scr_droite;
  dessin_sprite;
end; { scroll_droite }

procedure scroll_bas_gauche;
begin
  scr_bas;
  scr_gauche;
  dessin_sprite;
end; { scroll_bas_gauche }

procedure scroll_bas;
begin
  scr_bas;
  dessin_sprite;
end; { scroll_bas }

procedure scroll_bas_droite;
begin
  scr_droite;
  scr_bas;
  dessin_sprite;
end; { scroll_bas_droite }

procedure swap_horizontal;
var
   i, j, k : byte;
begin
  for i := 0 to 31 do
    for j := 0 to 63 do
      begin
        k := sprite [i, j];
        sprite [i, j] := sprite [63-i, j];
        sprite [63-i, j] := k;
      end;
    {endfor}
  {endfor}
  dessin_sprite;
end; { swap_horizontal }

procedure traitement;
var
   fin,
   code_nul : boolean;
   c : char;
   i : integer;
begin
  dessin_ecran;
  fin := false;
  repeat
    zone^.test_souris (code_nul, c);
    i := succ (ord (c) - ord (touche_f1));
    if (code_nul)
    then
      if ((c >= touche_f1) and (c <= touche_f10))
      then
        if (icn [i] <> nil)
        then
          icn [i]^.aff_enfonce (icn_x [i], icn_y [i]);
        {endif}
      {endif}
    {endif}
    case code_nul of
      false :
        case c of
          touche_escape : fin := confirm (get_msg (7));
          '7' : scroll_haut_gauche;
          '8' : scroll_haut;
          '9' : scroll_haut_droite;
          '4' : scroll_gauche;
          '6' : scroll_droite;
          '1' : scroll_bas_gauche;
          '2' : scroll_bas;
          '3' : scroll_bas_droite;
          '5' : swap_horizontal;
        end;
      true :
        case c of
          touche_f1 : informations;
          touche_f2 : sauver_spr;
          touche_f3 : charger_spr;
          touche_f4 : charger_pal;
          touche_f5 : run_camera;
          touche_f6 : sprite2tampon;
          touche_f7 : tampon2sprite;
          touche_f8 : do_undo;
          touche_f9 :;
          touche_alt_x,
          touche_f10 : fin := confirm (get_msg (7));
          touche_page_up :
            begin
              if (couleur-12 < 16+11)
              then
                couleur := 16
              else
                dec (couleur, 12);
              {endif}
              dessin_couleur;
            end;
          touche_page_dn :
            begin
              if (couleur+12 > 255-11)
              then
                couleur := 255-11
              else
                inc (couleur, 12);
              {endif}
              dessin_couleur;
            end;
          touche_gauche :
            if (num_spr > 0)
            then
              change_sprite (pred (num_spr));
            {endif}
          touche_droite :
            if (num_spr <= nb_spr)
            then
              change_sprite (succ (num_spr));
            {endif}
          #255 :
            if (pos_m_k = 1)
            then
              set_point
            else
              rempli_zone;
            {endif}
          touche_haut :
            begin
              if (indice > 0)
              then
                dec (indice)
              else
                indice := 12;
              {endif}
              dessin_couleur;
            end;
          touche_bas :
            begin
              if (indice < 12)
              then
                inc (indice)
              else
                indice := 0;
              {endif}
              dessin_couleur;
            end;
          #200..#212 :
            begin
              indice := ord (c)-200;
              dessin_couleur;
            end;
        end;
    end;
    if (code_nul)
    then
      if ((c >= touche_f1) and (c <= touche_f10))
      then
        if (icn [i] <> nil)
        then
          icn [i]^.aff_sortie (icn_x [i], icn_y [i]);
        {endif}
      {endif}
    {endif}
  until fin;
end; { traitement }

begin
  om := get_mode;
  init_licence ('MKSPR');
  init_olf_message (mess_shareware);
  init_olf_software ('Sprite Maker '+num_ver, '(c) Patrick Premartin '+dat_ver);
  if (not set_mode (19))
  then
    begin
      writeln (get_msg (1));
      halt (1);
    end
  else
    directvideo := false;
  {endif}
  init;
  traitement;
  done;
  repeat
  until (set_mode (om) or true);
  textattr := lightgray;
  clrscr;
  writeln (get_msg (2));
end.
